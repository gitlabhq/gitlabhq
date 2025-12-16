# frozen_string_literal: true

require 'gitlab_query_language'
require 'yaml'

module API
  class Glql < ::API::Base
    include ::API::Concerns::AiWorkflowsAccess
    include APIGuard

    feature_category :custom_dashboards_foundation
    urgency :low

    # Although this API endpoint responds to POST requests, it is a read-only operation
    allow_access_with_scope :read_api
    allow_ai_workflows_access

    MAXIMUM_QUERY_LIMIT = 100

    before do
      set_current_organization
    end

    helpers do
      def get_compile_context(fields:, user: nil, sort: nil, project: nil, group: nil)
        context = {
          fields: fields,
          featureFlags: {
            glqlWorkItems: Feature.enabled?(:glql_work_items, user)
          }
        }

        context[:username] = user.username if user.present?
        context[:sort] = sort if sort
        context[:project] = project if project
        context[:group] = group if group && !project

        context
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
        compile_context = get_compile_context(
          user: current_user,
          fields: config['fields'] || 'title',
          sort: config['sort'],
          project: config['project'],
          group: config['group']
        )

        ::Glql.compile(parsed_glql[:query], compile_context)
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

        query_service.execute(query: compiled_glql['output'], variables: variables)
      end

      def log_glql_execution(glql_yaml, compiled_glql, config, result)
        query_sha = Digest::SHA256.hexdigest(glql_yaml)

        ::Analytics::Glql::LoggingService.new(
          current_user: current_user,
          result: result,
          query_sha: query_sha,
          glql_query: glql_yaml,
          generated_graphql: compiled_glql['output'],
          fields: config['fields'] || 'title',
          context: get_compile_context(
            user: current_user,
            fields: config['fields'] || 'title',
            sort: config['sort'],
            project: config['project'],
            group: config['group']
          )
        ).execute
      end

      def transform_glql_result(glql_result, fields)
        transform_context = { fields: fields || 'title' }
        transform_context[:username] = current_user.username if current_user.present?

        ::Glql.transform(glql_result[:data], transform_context)
      end
    end

    resource :glql do
      desc 'Execute GLQL query' do
        detail 'Execute a GLQL (GitLab Query Language) query'
        success code: 200
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
      end
      post do
        parsed_glql = parse_glql_yaml(params[:glql_yaml])

        compiled_glql = compile_glql(parsed_glql)
        bad_request!(compiled_glql['output']) unless compiled_glql['success']

        glql_result = execute_glql_query(compiled_glql, parsed_glql[:config])
        log_glql_execution(params[:glql_yaml], compiled_glql, parsed_glql[:config], glql_result)
        error!(glql_result[:errors].first[:message], 429) if glql_result[:rate_limited]

        transformed_result = transform_glql_result(glql_result, parsed_glql[:config]['fields'])
        bad_request!(transformed_result['error']) unless transformed_result['success']

        status 200
        transformed_result
      rescue ArgumentError => e
        bad_request!(e.message)
      end
    end
  end
end
