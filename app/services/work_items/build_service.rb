# frozen_string_literal: true

module WorkItems
  class BuildService < ::Issues::BuildService
    private

    def model_klass
      ::WorkItem
    end
  end
end
