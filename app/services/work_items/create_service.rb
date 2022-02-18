# frozen_string_literal: true

module WorkItems
  class CreateService
    include ::Services::ReturnServiceResponses

    def initialize(project:, current_user: nil, params: {}, spam_params:)
      @create_service = ::Issues::CreateService.new(
        project: project,
        current_user: current_user,
        params: params,
        spam_params: spam_params,
        build_service: ::WorkItems::BuildService.new(project: project, current_user: current_user, params: params)
      )
      @current_user = current_user
      @project = project
    end

    def execute
      unless @current_user.can?(:create_work_item, @project)
        return error(_('Operation not allowed'), :forbidden)
      end

      work_item = @create_service.execute

      if work_item.valid?
        success(payload(work_item))
      else
        error(work_item.errors.full_messages, :unprocessable_entity, pass_back: payload(work_item))
      end
    end

    private

    def payload(work_item)
      { work_item: work_item }
    end
  end
end
