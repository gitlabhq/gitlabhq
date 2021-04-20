# frozen_string_literal: true

module Milestones
  class FindOrCreateService
    attr_accessor :project, :current_user, :params

    def initialize(project, user, params = {})
      @project = project
      @current_user = user
      @params = params.dup
    end

    def execute
      find_milestone || create_milestone
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def find_milestone
      groups = project.group&.self_and_ancestors_ids
      Milestone.for_projects_and_groups([project.id], groups).find_by(title: params["title"])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_milestone
      return unless current_user.can?(:admin_milestone, project)

      new_milestone if new_milestone.persisted?
    end

    def new_milestone
      @new_milestone ||= CreateService.new(project, current_user, params).execute
    end
  end
end
