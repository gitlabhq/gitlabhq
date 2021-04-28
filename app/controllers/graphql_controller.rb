# frozen_string_literal: true

class GraphqlController < ApplicationController
  # Unauthenticated users have access to the API for public data
  skip_before_action :authenticate_user!

  WHITELIST_HEADER = 'HTTP_X_GITLAB_QUERY_WHITELIST_ISSUE'

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

  before_action :authorize_access_api!
  before_action(only: [:execute]) { authenticate_sessionless_user!(:api) }
  before_action :set_user_last_activity
  before_action :track_vs_code_usage
  before_action :whitelist_query!

  # Since we deactivate authentication from the main ApplicationController and
  # defer it to :authorize_access_api!, we need to override the bypass session
  # callback execution order here
  around_action :sessionless_bypass_admin_mode!, if: :sessionless_user?

  feature_category :not_owned

  def execute
    result = multiplex? ? execute_multiplex : execute_query

    render json: result
  end

  rescue_from StandardError do |exception|
    log_exception(exception)

    if Rails.env.test? || Rails.env.development?
      render_error("Internal server error: #{exception.message}")
    else
      render_error("Internal server error")
    end
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

  private

  # Tests may mark some queries as exempt from query limits
  def whitelist_query!
    whitelist_issue = request.headers[WHITELIST_HEADER]
    return unless whitelist_issue

    Gitlab::QueryLimiting.whitelist(whitelist_issue)
  end

  def set_user_last_activity
    return unless current_user

    Users::ActivityService.new(current_user).execute
  end

  def track_vs_code_usage
    Gitlab::UsageDataCounters::VSCodeExtensionActivityUniqueCounter
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
    params[:query]
  end

  def multiplex_queries
    params[:_json].map do |single_query_info|
      {
        query: single_query_info[:query],
        variables: build_variables(single_query_info[:variables]),
        operation_name: single_query_info[:operationName],
        context: context
      }
    end
  end

  def context
    api_user = !!sessionless_user?
    @context ||= {
      current_user: current_user,
      is_sessionless_user: api_user,
      request: request,
      scope_validator: ::Gitlab::Auth::ScopeValidator.new(api_user, request_authenticator)
    }
  end

  def build_variables(variable_info)
    Gitlab::Graphql::Variables.new(variable_info).to_h
  end

  def multiplex?
    params[:_json].present?
  end

  def authorize_access_api!
    access_denied!("API not accessible for user.") unless can?(current_user, :access_api)
  end

  # Overridden from the ApplicationController to make the response look like
  # a GraphQL response. That is nicely picked up in Graphiql.
  def render_404
    render_error("Not found!", status: :not_found)
  end

  def render_error(message, status: 500)
    error = { errors: [message: message] }

    render json: error, status: status
  end

  def append_info_to_payload(payload)
    super

    # Merging to :metadata will ensure these are logged as top level keys
    payload[:metadata] ||= {}
    payload[:metadata].merge!(graphql: logs)
  end

  def logs
    RequestStore.store[:graphql_logs].to_h
                .except(:duration_s, :query_string)
                .merge(operation_name: params[:operationName])
  end
end
