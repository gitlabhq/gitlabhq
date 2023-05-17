# frozen_string_literal: true

class GraphqlController < ApplicationController
  extend ::Gitlab::Utils::Override

  # Unauthenticated users have access to the API for public data
  skip_before_action :authenticate_user!

  # Header can be passed by tests to disable SQL query limits.
  DISABLE_SQL_QUERY_LIMIT_HEADER = 'HTTP_X_GITLAB_DISABLE_SQL_QUERY_LIMIT'

  # Max size of the query text in characters
  MAX_QUERY_SIZE = 10_000

  # If a user is using their session to access GraphQL, we need to have session
  # storage, since the admin-mode check is session wide.
  # We can't enable this for anonymous users because that would cause users using
  # enforced SSO from using an auth token to access the API.
  skip_around_action :set_session_storage, unless: :current_user

  # Allow missing CSRF tokens, this would mean that if a CSRF is invalid or missing,
  # the user won't be authenticated but can proceed as an anonymous user.
  #
  # If a CSRF is valid, the user is authenticated. This makes it easier to play
  # around in GraphiQL.
  protect_from_forgery with: :null_session, only: :execute

  # must come first: current_user is set up here
  before_action(only: [:execute]) { authenticate_sessionless_user!(:api) }

  before_action :authorize_access_api!
  before_action :set_user_last_activity
  before_action :track_vs_code_usage
  before_action :track_jetbrains_usage
  before_action :track_gitlab_cli_usage
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
    result = multiplex? ? execute_multiplex : execute_query
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

  rescue_from Gitlab::Auth::TooManyIps do |exception|
    log_exception(exception)

    render_error(exception.message, status: :forbidden)
  end

  rescue_from Gitlab::Git::ResourceExhaustedError do |exception|
    log_exception(exception)

    response.headers.merge!(exception.headers)
    render_error(exception.message, status: :too_many_requests)
  end

  rescue_from Gitlab::Graphql::Variables::Invalid do |exception|
    render_error(exception.message, status: :unprocessable_entity)
  end

  rescue_from Gitlab::Graphql::Errors::ArgumentError do |exception|
    render_error(exception.message, status: :unprocessable_entity)
  end

  rescue_from ::GraphQL::CoercionError do |exception|
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

  def permitted_multiplex_params
    params.permit(_json: [:query, :operationName, { variables: {} }])
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

  def mutation?(query_string, operation_name = params[:operationName])
    ::GraphQL::Query.new(GitlabSchema, query_string, operation_name: operation_name).mutation?
  end

  # Tests may mark some GraphQL queries as exempt from SQL query limits
  def disable_query_limiting
    return unless Gitlab::QueryLimiting.enabled_for_env?

    disable_issue = request.headers[DISABLE_SQL_QUERY_LIMIT_HEADER]
    return unless disable_issue

    Gitlab::QueryLimiting.disable!(disable_issue)
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

  def track_gitlab_cli_usage
    Gitlab::UsageDataCounters::GitLabCliActivityUniqueCounter
      .track_api_request_when_trackable(user_agent: request.user_agent, user: current_user)
  end

  def execute_multiplex
    GitlabSchema.multiplex(multiplex_queries, context: context)
  end

  def execute_query
    variables = build_variables(params[:variables])
    operation_name = params[:operationName]

    GitlabSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
  end

  def query
    params.fetch(:query, '')
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
      remove_deprecated: Gitlab::Utils.to_boolean(params[:remove_deprecated], default: false)
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

    payload[:exception_object] = @exception_object if @exception_object
  end

  def logs
    RequestStore.store[:graphql_logs].to_a
  end
end
