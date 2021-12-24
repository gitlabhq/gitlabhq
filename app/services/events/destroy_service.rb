# frozen_string_literal: true

module Events
  class DestroyService
    BATCH_SIZE = 50

    def initialize(project)
      @project = project
    end

    def execute
      loop do
        count = delete_events_in_batches
        break if count < BATCH_SIZE
      end

      ServiceResponse.success(message: 'Events were deleted.')
    rescue StandardError => e
      ServiceResponse.error(message: e.message)
    end

    private

    attr_reader :project

    def delete_events_in_batches
      project.events.limit(BATCH_SIZE).delete_all
    end
  end
end
