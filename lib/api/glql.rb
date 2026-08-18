# frozen_string_literal: true

require 'gitlab_query_language'
require 'yaml'

module API
  class Glql < ::API::Base
    include ::API::Concerns::AiWorkflowsAccess
    include APIGuard

    feature_category :custom_dashboards_foundation
    # Urgency is set per route because the two endpoints do very different
    # amounts of work. It cannot also be set class-wide: a route overriding an
    # attribute already defined for all actions raises, see
    # Gitlab::EndpointAttributes::Config#set_attributes_for_actions.

    # Although this API endpoint responds to POST requests, it is a read-only operation
    allow_access_with_scope :read_api
    allow_ai_workflows_access

    MAXIMUM_QUERY_LIMIT = 100

    helpers do
      def get_compile_context(
        fields: nil,
        dimensions: nil,
        metrics: nil,
        user: nil,
        mode: 'standard',
        sort: nil,
        project: nil,
        group: nil
      )
        {
          featureFlags: {},
          username: user&.username,
          mode: mode,
          sort: sort,
          project: project,
          group: group,
          fields: fields,
          dimensions: dimensions,
          metrics: metrics
        }.compact
      end

      # Ensure limit is a valid int and doesn't exceed maximum, default to the maximum
      def get_limit(param_limit)
        return MAXIMUM_QUERY_LIMIT unless param_limit.present?

        limit = param_limit.to_i

        return MAXIMUM_QUERY_LIMIT if limit <= 0 || limit > MAXIMUM_QUERY_LIMIT

        limit
      end

      def get_variables(glql_variables)
        return {} if glql_variables.nil? || glql_variables.empty?

        glql_variables.transform_values { |variable_data| variable_data["value"] }
      end

      def parse_glql_yaml(glql_yaml)
        parser_service = ::Analytics::Glql::ParserService.new(glql_yaml: glql_yaml)
        parser_service.execute
      end

      def compile_glql(parsed_glql)
        config = parsed_glql[:config]

        compile_context = get_compile_context(**{
          user: current_user,
          mode: config['mode'],
          fields: config['fields'],
          dimensions: config['dimensions'],
          metrics: config['metrics'],
          sort: config['sort'],
          project: config['project'],
          group: config['group']
        }.compact)

        compiled = ::Glql.compile(parsed_glql[:query], compile_context)
        [compiled, compile_context]
      end

      def execute_glql_query(compiled_glql, config)
        query_service = ::Analytics::Glql::QueryService.new(
          current_user: current_user,
          original_query: params[:glql_yaml],
          request: request,
          current_organization: Current.organization
        )

        variables = get_variables(compiled_glql['variables'])
        variables['limit'] = get_limit(config['limit'])
        variables['after'] = params[:after] if params[:after].present?

        query_service.execute(query: compiled_glql['output'], variables: variables)
      end

      def log_glql_execution(glql_yaml, compiled_glql, config, result, compile_context)
        query_sha = Digest::SHA256.hexdigest(glql_yaml)

        ::Analytics::Glql::LoggingService.new(
          current_user: current_user,
          result: result,
          query_sha: query_sha,
          glql_query: glql_yaml,
          generated_graphql: compiled_glql['output'],
          fields: config['fields'],
          context: compile_context
        ).execute
      end

      def transform_glql_result(glql_result, fields, mode: nil, source: nil)
        transform_context = { fields: fields, mode: mode, source: source }
        transform_context[:username] = current_user.username if current_user.present?

        ::Glql.transform(glql_result[:data], transform_context)
      end
    end

    resource :glql do
      desc 'Execute a GLQL query' do
        detail 'Executes a GLQL query to search and filter GitLab resources.'
        success code: 200, model: ::API::Entities::Glql::Result
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 429, message: 'Too Many Requests' },
          { code: 500, message: 'Internal server error' }
        ]
        tags %w[glql]
      end
      params do
        requires :glql_yaml, type: String, desc: 'The full GLQL code block containing YAML configuration and query',
          allow_blank: false

        optional :after, type: String,
          desc: 'Cursor for forward pagination. Use the `endCursor` from previous response to fetch the next page'
      end
      route_setting :authorization, permissions: :read_glql, boundary_type: :user
      post urgency: :low do
        parsed_glql = parse_glql_yaml(params[:glql_yaml])

        compiled_glql, compile_context = compile_glql(parsed_glql)
        error!(compiled_glql['output'], 400) unless compiled_glql['success']

        glql_result = execute_glql_query(compiled_glql, parsed_glql[:config])
        log_glql_execution(params[:glql_yaml], compiled_glql, parsed_glql[:config], glql_result, compile_context)
        error!(glql_result[:errors].first[:message], 429) if glql_result[:rate_limited]
        error!(glql_result[:errors].first[:message], 400) if glql_result[:errors]

        transformed_result = transform_glql_result(glql_result, compiled_glql['fields'],
          mode: compiled_glql['mode'], source: compiled_glql['source'])
        error!(transformed_result['error'], 400) unless transformed_result['success']

        status 200
        present transformed_result.deep_symbolize_keys, with: ::API::Entities::Glql::Result
      rescue ArgumentError => e
        error!(e.message, 400)
      end

      desc 'Retrieve the GLQL schema' do
        detail 'Retrieves the GLQL schema: data sources with their filter, display and sort ' \
          'fields, the operator, value kind and reference type vocabularies, the available ' \
          'functions, and the display types a query can be rendered as.'
        success code: 200
        failure [
          { code: 500, message: 'Internal server error' }
        ]
        tags %w[glql]
      end
      # The document describes the query language and is identical for everyone,
      # so it gives away no more than reading the GLQL source would. Declaring it
      # public rather than gating it on `read_glql` keeps a granular token scoped
      # to something else from getting a 403 where an anonymous caller gets a 200.
      route_setting :authorization, skip_granular_token_authorization: :public_endpoint
      # Serves a memoized hash and does no I/O, unlike the query endpoint.
      get :schema, urgency: :high do
        present ::Analytics::Glql::Schema.document
      end
    end
  end
end
