class GraphqlController < ApplicationController
  # Unauthenticated users have access to the API for public data
  skip_before_action :authenticate_user!

  before_action :check_graphql_feature_flag!

  def execute
    variables = Gitlab::Graphql::Variables.new(params[:variables]).to_h
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: current_user
    }
    result = GitlabSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  end

  rescue_from StandardError do |exception|
    log_exception(exception)

    render_error("Internal server error")
  end

  rescue_from Gitlab::Graphql::Variables::Invalid do |exception|
    render_error(exception.message, status: :unprocessable_entity)
  end

  private

  # Overridden from the ApplicationController to make the response look like
  # a GraphQL response. That is nicely picked up in Graphiql.
  def render_404
    render_error("Not found!", status: :not_found)
  end

  def render_error(message, status: 500)
    error = { errors: [message: message] }

    render json: error, status: status
  end

  def check_graphql_feature_flag!
    render_404 unless Feature.enabled?(:graphql)
  end
end
