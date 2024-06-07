# frozen_string_literal: true

module Ci
  class PipelineSchedulesFinder
    attr_reader :project, :pipeline_schedules, :params

    def initialize(project, params = {})
      @project = project
      @pipeline_schedules = project.pipeline_schedules
      @params = params
    end

    def execute(scope: nil, ids: nil)
      items = pipeline_schedules
      items = by_ids(items, ids)
      items = by_scope(items, scope)

      sort_items(items)
    end

    private

    def by_ids(items, ids)
      if ids.present?
        items.id_in(ids)
      else
        items
      end
    end

    def by_scope(items, scope)
      case scope
      when 'active'
        items.active
      when 'inactive'
        items.inactive
      else
        items
      end
    end

    def sort_items(items)
      return items unless params[:sort]

      items.sort_by_attribute(params[:sort])
    end
  end
end
