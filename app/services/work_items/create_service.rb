# frozen_string_literal: true

module WorkItems
  class CreateService
    def initialize(project:, current_user: nil, params: {}, spam_params:)
      @create_service = ::Issues::CreateService.new(
        project: project,
        current_user: current_user,
        params: params,
        spam_params: spam_params,
        build_service: ::WorkItems::BuildService.new(project: project, current_user: current_user, params: params)
      )
    end

    def execute
      @create_service.execute
    end
  end
end
