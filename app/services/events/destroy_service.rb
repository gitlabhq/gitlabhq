# frozen_string_literal: true

module Events
  class DestroyService
    def initialize(project)
      @project = project
    end

    def execute
      project.events.all.delete_all

      ServiceResponse.success(message: 'Events were deleted.')
    rescue StandardError
      ServiceResponse.error(message: 'Failed to remove events.')
    end

    private

    attr_reader :project
  end
end
