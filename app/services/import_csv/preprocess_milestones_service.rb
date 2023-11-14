# frozen_string_literal: true

module ImportCsv
  class PreprocessMilestonesService < BaseService
    def initialize(user, project, provided_titles)
      @user = user
      @project = project
      @provided_titles = provided_titles

      @results = { success: 0, errors: nil }
      @milestone_errors = { missing: { header: {}, titles: [] } }
    end

    attr_reader :user, :project, :provided_titles, :results, :milestone_errors

    def execute
      result = find_milestones_by_titles
      available_milestones = result.map(&:title).uniq.sort
      return ServiceResponse.success(payload: result) if provided_titles.sort == available_milestones

      milestone_errors[:missing][:header] = 'Milestone'
      milestone_errors[:missing][:titles] = provided_titles.difference(available_milestones) || []
      ServiceResponse.error(message: "", payload: milestone_errors)
    end

    def find_milestones_by_titles
      # Find if these milestones exist in the project or its group and group ancestors
      finder_params = {
        project_ids: [project.id],
        title: provided_titles
      }
      finder_params[:group_ids] = project.group.self_and_ancestors.select(:id) if project.group
      MilestonesFinder.new(finder_params).execute
    end
  end
end
