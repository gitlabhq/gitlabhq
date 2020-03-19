# frozen_string_literal: true

module Ci
  class PipelineSchedulesFinder
    attr_reader :project, :pipeline_schedules

    def initialize(project)
      @project = project
      @pipeline_schedules = project.pipeline_schedules
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute(scope: nil)
      scoped_schedules =
        case scope
        when 'active'
          pipeline_schedules.active
        when 'inactive'
          pipeline_schedules.inactive
        else
          pipeline_schedules
        end

      scoped_schedules.order(id: :desc)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
