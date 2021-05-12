# frozen_string_literal: true

# This service fetches all branches containing the current issue's ID, except for
# those with a merge request open referencing the current issue.
module Issues
  class RelatedBranchesService < Issues::BaseService
    def execute(issue)
      branch_names = branches_with_iid_of(issue) - branches_with_merge_request_for(issue)
      branch_names.map { |branch_name| branch_data(branch_name) }
    end

    private

    def branch_data(branch_name)
      {
        name: branch_name,
        pipeline_status: pipeline_status(branch_name)
      }
    end

    def pipeline_status(branch_name)
      branch = project.repository.find_branch(branch_name)
      target = branch&.dereferenced_target

      return unless target

      pipeline = project.latest_pipeline(branch_name, target.sha)
      pipeline.detailed_status(current_user) if can?(current_user, :read_pipeline, pipeline)
    end

    def branches_with_merge_request_for(issue)
      Issues::ReferencedMergeRequestsService
        .new(project: project, current_user: current_user)
        .referenced_merge_requests(issue)
        .map(&:source_branch)
    end

    def branches_with_iid_of(issue)
      project.repository.branch_names.select do |branch|
        branch =~ /\A#{issue.iid}-(?!\d+-stable)/i
      end
    end
  end
end
