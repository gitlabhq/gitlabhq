# frozen_string_literal: true

module Glql
  class BaseController < GraphqlController
    before_action :set_namespace_context, only: [:execute] # rubocop:disable Rails/LexicallyScopedActionFilter -- execute is defined in the parent GraphqlController

    rescue_from ::Analytics::Glql::QueryService::GlqlQueryLockedError do |exception|
      log_exception(exception)

      render_error(exception.message, status: :forbidden)
    end

    protected

    # Overrides GraphqlController#execute_single_query to add rate limiting for
    # GLQL queries.
    # Uses the shared QueryService for consistent behavior with API::Glql.
    #
    # normalized_query is passed explicitly by the parent's execute() to guarantee
    # the validator (disallow_mutations_for_get) and executor always operate on an
    # identical string. Do not use permitted_params[:query] here for execution.
    def execute_single_query(normalized_query)
      query_service = ::Analytics::Glql::QueryService.new(
        current_user: current_user,
        original_query: normalized_query,
        request: request,
        current_organization: Current.organization
      )

      result = query_service.execute(
        query: normalized_query,
        variables: permitted_params[:variables].to_h,
        context: context,
        operation_name: permitted_params[:operationName]
      )

      # Handle rate limiting
      if result[:rate_limited]
        raise ::Analytics::Glql::QueryService::GlqlQueryLockedError,
          result[:errors].first[:message]
      end

      # Handle timeout
      if result[:timeout_occurred]
        render_error('Query timed out', status: :service_unavailable)
        return
      end

      # Handle other exceptions
      raise result[:exception] if result[:exception]

      # Return the result in the format expected by GraphqlController
      response_data = { 'data' => result[:data] }
      response_data['errors'] = result[:errors] if result[:errors]

      response_data
    end

    private

    # When `set_current_context` in app/controllers/application_controller.rb calls
    # `to_lazy_hash` on Gitlab::ApplicationContext, the meta fields (meta.project and
    # meta.root_namespace) will be populated using @group or @project variables.
    def set_namespace_context
      @project ||= Project.find_by_full_path(permitted_params[:project]) if permitted_params[:project].present?
      @group ||= Group.find_by_full_path(permitted_params[:group]) if permitted_params[:group].present?
    end

    # Overrides GraphqlController#permitted_params to permit project and group params
    def permitted_standalone_query_params
      params.permit(:query, :operationName, :remove_deprecated, :group, :project, variables: {})
    end
  end
end
