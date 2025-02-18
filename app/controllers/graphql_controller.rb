# frozen_string_literal: true

class GraphqlController < ApplicationController
  include Gitlab::Auth::AuthFinders
  extend ::Gitlab::Utils::Override

  # Unauthenticated users have access to the API for public data
  skip_before_action :authenticate_user!
  # This is already handled by authorize_access_api!
  skip_before_action :active_user_check
  # CSRF protection is only necessary when the request is authenticated via a session cookie.
  # Also, we allow anonymous users to access the API without a CSRF token so that it is easier for users
  # to get started with our GraphQL API.
  skip_before_action :verify_authenticity_token, if: -> {
    current_user.nil? || sessionless_user? || !any_mutating_query?
  }
  skip_before_action :check_two_factor_requirement, if: -> { sessionless_user? }

  # Header can be passed by tests to disable SQL query limits.
  DISABLE_SQL_QUERY_LIMIT_HEADER = 'HTTP_X_GITLAB_DISABLE_SQL_QUERY_LIMIT'

  # Max size of the query text in characters
  MAX_QUERY_SIZE = 10_000

  # The query string of a standard IntrospectionQuery, used to compare incoming requests for caching
  CACHED_INTROSPECTION_QUERY_STRING = CachedIntrospectionQuery.query_string
  INTROSPECTION_QUERY_OPERATION_NAME = 'IntrospectionQuery'

  # must come first: current_user is set up here
  prepend_before_action { authenticate_sessionless_user!(:graphql_api) }

  before_action :authorize_access_api!
  before_action(only: [:execute]) { check_dpop! }
  before_action :set_user_last_activity
  before_action :track_vs_code_usage
  before_action :track_jetbrains_usage
  before_action :track_jetbrains_bundled_usage
  before_action :track_gitlab_cli_usage
  before_action :track_visual_studio_usage
  before_action :track_neovim_plugin_usage
  before_action :disable_query_limiting
  before_action :limit_query_size

  before_action :disallow_mutations_for_get

  # Since we deactivate authentication from the main ApplicationController and
  # defer it to :authorize_access_api!, we need to override the bypass session
  # callback execution order here
  around_action :sessionless_bypass_admin_mode!, if: :sessionless_user?

  # The default feature category is overridden to read from request
  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  # We don't know what the query is going to be, so we can't set a high urgency
  # See https://gitlab.com/groups/gitlab-org/-/epics/5841 for the work that will
  # allow us to specify an urgency per query.
  # Currently, all queries have a default urgency. And this is measured in the `graphql_queries`
  # SLI. But queries could be multiplexed, so the total duration could be longer.
  urgency :low, [:execute]

  def execute
    result = if multiplex?
               execute_multiplex
             else
               introspection_query? ? execute_introspection_query : execute_query
             end

    render json: result
  end

  rescue_from StandardError do |exception|
    @exception_object = exception

    log_exception(exception)

    if Rails.env.test? || Rails.env.development?
      render_error("Internal server error: #{exception.message}", raised_at: exception.backtrace[0..10].join(' <-- '))
    else
      render_error("Internal server error")
    end
  end

  rescue_from Gitlab::Auth::DpopValidationError do |exception|
    log_exception(exception)

    render_error(exception.message, status: :unauthorized)
  end

  # ApplicationController has similar rescues but we declare these again here because the
  # `rescue_from StandardError` above would prevent these from bubbling up to ApplicationController.
  # These also return errors in a JSON format similar to GraphQL errors.
  rescue_from ActionController::InvalidAuthenticityToken do |exception|
    render_error(exception.message, status: :unprocessable_entity)
  end

  rescue_from Gitlab::Auth::TooManyIps do |exception|
    log_exception(exception)

    render_error(exception.message, status: :forbidden)
  end

  rescue_from Gitlab::Git::ResourceExhaustedError do |exception|
    log_exception(exception)

    response.headers.merge!(exception.headers)
    render_error(exception.message, status: :service_unavailable)
  end

  rescue_from Gitlab::Graphql::Variables::Invalid do |exception|
    render_error(exception.message, status: :unprocessable_entity)
  end

  rescue_from Gitlab::Graphql::Errors::ArgumentError do |exception|
    render_error(exception.message, status: :unprocessable_entity)
  end

  rescue_from ActiveRecord::QueryAborted do |exception|
    log_exception(exception)

    error = "Request timed out. Please try a less complex query or a smaller set of records."
    render_error(error, status: :service_unavailable)
  end

  override :feature_category
  def feature_category
    ::Gitlab::FeatureCategories.default.from_request(request) || super
  end

  private

  def check_dpop!
    return unless current_user && Feature.enabled?(:dpop_authentication, current_user)

    token = extract_personal_access_token
    return unless PersonalAccessToken.find_by_token(token.to_s) # The token is not PAT, exit early

    # For authenticated requests we check if the user has DPoP enabled
    ::Auth::DpopAuthenticationService.new(current_user: current_user,
      personal_access_token_plaintext: token,
      request: current_request).execute
  end

  def permitted_params
    @permitted_params ||= multiplex? ? permitted_multiplex_params : permitted_standalone_query_params
  end

  def permitted_standalone_query_params
    params.permit(:query, :operationName, :remove_deprecated, variables: {}).tap do |permitted_params|
      permitted_params[:variables] = params[:variables]
    end
  end

  def permitted_multiplex_params
    params.permit(:remove_deprecated, _json: [:query, :operationName, { variables: {} }])
  end

  def disallow_mutations_for_get
    return unless request.get? || request.head?
    return unless any_mutating_query?

    raise ::Gitlab::Graphql::Errors::ArgumentError, "Mutations are forbidden in #{request.request_method} requests"
  end

  def limit_query_size
    total_size = if multiplex?
                   multiplex_param.sum { _1[:query].size }
                 else
                   query.size
                 end

    raise ::Gitlab::Graphql::Errors::ArgumentError, "Query too large" if total_size > MAX_QUERY_SIZE
  end

  def any_mutating_query?
    if multiplex?
      multiplex_queries.any? { |q| mutation?(q[:query], q[:operation_name]) }
    else
      mutation?(query)
    end
  end

  def mutation?(query_string, operation_name = permitted_params[:operationName])
    ::GraphQL::Query.new(GitlabSchema, query_string, operation_name: operation_name).mutation?
  end

  # Tests may mark some GraphQL queries as exempt from SQL query limits
  def disable_query_limiting
    return unless Gitlab::QueryLimiting.enabled_for_env?

    disable_reference = request.headers[DISABLE_SQL_QUERY_LIMIT_HEADER]
    return unless disable_reference

    first, second = disable_reference.split(',')

    if first.match?(/^\d+$/)
      Gitlab::QueryLimiting.disable!(second, new_threshold: first&.to_i)
    else
      Gitlab::QueryLimiting.disable!(first)
    end
  end

  def set_user_last_activity
    return unless current_user

    # TODO: add namespace & project - https://gitlab.com/gitlab-org/gitlab/-/issues/387951
    Users::ActivityService.new(author: current_user).execute
  end

  def track_vs_code_usage
    Gitlab::UsageDataCounters::VSCodeExtensionActivityUniqueCounter
      .track_api_request_when_trackable(user_agent: request.user_agent, user: current_user)
  end

  def track_jetbrains_usage
    Gitlab::UsageDataCounters::JetBrainsPluginActivityUniqueCounter
      .track_api_request_when_trackable(user_agent: request.user_agent, user: current_user)
  end

  def track_jetbrains_bundled_usage
    Gitlab::UsageDataCounters::JetBrainsBundledPluginActivityUniqueCounter
      .track_api_request_when_trackable(user_agent: request.user_agent, user: current_user)
  end

  def track_visual_studio_usage
    Gitlab::UsageDataCounters::VisualStudioExtensionActivityUniqueCounter
      .track_api_request_when_trackable(user_agent: request.user_agent, user: current_user)
  end

  def track_neovim_plugin_usage
    Gitlab::UsageDataCounters::NeovimPluginActivityUniqueCounter
      .track_api_request_when_trackable(user_agent: request.user_agent, user: current_user)
  end

  def track_gitlab_cli_usage
    Gitlab::UsageDataCounters::GitLabCliActivityUniqueCounter
      .track_api_request_when_trackable(user_agent: request.user_agent, user: current_user)
  end

  def execute_multiplex
    GitlabSchema.multiplex(multiplex_queries, context: context)
  end

  def execute_query
    variables = build_variables(permitted_params[:variables])
    operation_name = permitted_params[:operationName]
    GitlabSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
  end

  def query
    GraphQL::Language.escape_single_quoted_newlines(permitted_params.fetch(:query, ''))
  end

  def multiplex_param
    permitted_multiplex_params[:_json]
  end

  def multiplex_queries
    multiplex_param.map do |single_query_info|
      {
        query: single_query_info[:query],
        variables: build_variables(single_query_info[:variables]),
        operation_name: single_query_info[:operationName],
        context: context
      }
    end
  end

  # When modifying the context, also update GraphqlChannel#context if needed
  # so that we have similar context when executing queries, mutations, and subscriptions
  def context
    api_user = !!sessionless_user?
    @context ||= {
      current_user: current_user,
      is_sessionless_user: api_user,
      request: request,
      scope_validator: ::Gitlab::Auth::ScopeValidator.new(api_user, request_authenticator),
      remove_deprecated: Gitlab::Utils.to_boolean(permitted_params[:remove_deprecated], default: false)
    }
  end

  def build_variables(variable_info)
    Gitlab::Graphql::Variables.new(variable_info).to_h
  end

  # We support Apollo-style query batching where an array of queries will be in the `_json:` key.
  # https://graphql-ruby.org/queries/multiplex.html#apollo-query-batching
  def multiplex?
    params[:_json].is_a?(Array)
  end

  def authorize_access_api!
    if current_user.nil? &&
        request_authenticator.authentication_token_present?
      return render_error('Invalid token', status: :unauthorized)
    end

    return if can?(current_user, :access_api)

    render_error('API not accessible for user', status: :forbidden)
  end

  # Overridden from the ApplicationController to make the response look like
  # a GraphQL response. That is nicely picked up in Graphiql.
  def render_404
    render_error("Not found!", status: :not_found)
  end

  def render_error(message, status: 500, raised_at: nil)
    error = { errors: [message: message] }
    error[:errors].first['raisedAt'] = raised_at if raised_at

    render json: error, status: status
  end

  def append_info_to_payload(payload)
    super

    # Merging to :metadata will ensure these are logged as top level keys
    payload[:metadata] ||= {}

    payload[:metadata][:graphql] = logs

    payload[:metadata][:referer] = request.headers['Referer'] if logs.any? { |log| log[:operation_name] == 'GLQL' }

    payload[:exception_object] = @exception_object if @exception_object
  end

  def logs
    RequestStore.store[:graphql_logs].to_a
  end

  def execute_introspection_query
    context[:introspection] = true

    if introspection_query_can_use_cache?
      # Context for caching: https://gitlab.com/gitlab-org/gitlab/-/issues/409448
      Rails.cache.fetch(
        introspection_query_cache_key,
        expires_in: 1.day) do
          execute_query.to_json
        end
    else
      execute_query
    end
  end

  def introspection_query_can_use_cache?
    return false if Gitlab.dev_or_test_env?

    CACHED_INTROSPECTION_QUERY_STRING == graphql_query_object.query_string.squish
  end

  def introspection_query_cache_key
    # We use context[:remove_deprecated] here as an introspection query result can differ based on the
    # visibility of schema items. Visibility can be affected by the remove_deprecated param. For more context, see:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/409448#note_1377558096
    ['introspection-query-cache', Gitlab.revision, context[:remove_deprecated]]
  end

  def introspection_query?
    if permitted_params.key?(:operationName)
      permitted_params[:operationName] == INTROSPECTION_QUERY_OPERATION_NAME
    else
      # If we don't provide operationName param, we infer it from the query
      graphql_query_object.selected_operation_name == INTROSPECTION_QUERY_OPERATION_NAME
    end
  end

  def graphql_query_object
    @graphql_query_object ||= GraphQL::Query.new(GitlabSchema, query: query,
      variables: build_variables(permitted_params[:variables]))
  end
end

GraphqlController.prepend_mod_with('GraphqlController')
