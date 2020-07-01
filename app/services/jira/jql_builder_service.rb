# frozen_string_literal: true

module Jira
  class JqlBuilderService
    DEFAULT_SORT = "created"
    DEFAULT_SORT_DIRECTION = "DESC"

    def initialize(jira_project_key, params = {})
      @jira_project_key = jira_project_key
      @sort = params[:sort] || DEFAULT_SORT
      @sort_direction = params[:sort_direction] || DEFAULT_SORT_DIRECTION
    end

    def execute
      [by_project, order_by].join(' ')
    end

    private

    attr_reader :jira_project_key, :sort, :sort_direction

    def by_project
      "project = #{jira_project_key}"
    end

    def order_by
      "order by #{sort} #{sort_direction}"
    end
  end
end
