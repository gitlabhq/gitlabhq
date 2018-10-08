# frozen_string_literal: true

# This service fetches all branches containing the current issue's ID, except for
# those with a merge request open referencing the current issue.
module Issues
  class RelatedBranchesService < Issues::BaseService
    def execute(issue)
      branches_with_iid_of(issue) - branches_with_merge_request_for(issue)
    end

    private

    def branches_with_merge_request_for(issue)
      Issues::ReferencedMergeRequestsService
        .new(project, current_user)
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
