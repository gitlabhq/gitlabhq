# frozen_string_literal: true

module Ci
  class GroupVariablesFinder
    SORT_TO_PARAMS_MAP = {
      created_desc: { order_by: 'created_at', sort: 'desc' },
      created_asc: { order_by: 'created_at', sort: 'asc' },
      key_desc: { order_by: 'key', sort: 'desc' },
      key_asc: { order_by: 'key', sort: 'asc' }
    }.freeze

    def initialize(project, sort_key = nil)
      @project = project
      @params = sort_to_params_map(sort_key)
    end

    def execute
      variables = ::Ci::GroupVariable.for_groups(project.group&.self_and_ancestor_ids)

      return Ci::GroupVariable.none if variables.empty?

      sort(variables)
    end

    private

    def sort_to_params_map(sort_key)
      SORT_TO_PARAMS_MAP[sort_key] || {}
    end

    def sort(variables)
      return variables unless params[:order_by]

      variables.sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
    end

    attr_reader :project, :params
  end
end
