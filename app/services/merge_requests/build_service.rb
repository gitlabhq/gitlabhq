module MergeRequests
  class BuildService < MergeRequests::BaseService
    def execute
      merge_request = MergeRequest.new(params)

      # Set MR attributes
      merge_request.can_be_created = false
      merge_request.compare_failed = false
      merge_request.compare_commits = []
      merge_request.compare_diffs = []
      merge_request.source_project = project unless merge_request.source_project
      merge_request.target_project ||= (project.forked_from_project || project)
      merge_request.target_branch ||= merge_request.target_project.default_branch

      unless merge_request.target_branch && merge_request.source_branch
        return build_failed(merge_request, nil)
      end

      compare_result = CompareService.new.execute(
        current_user,
        merge_request.source_project,
        merge_request.source_branch,
        merge_request.target_project,
        merge_request.target_branch,
      )

      commits = compare_result.commits

      # At this point we decide if merge request can be created
      # If we have at least one commit to merge -> creation allowed
      if commits.present?
        merge_request.compare_commits = Commit.decorate(commits)
        merge_request.can_be_created = true
        merge_request.compare_failed = false

        # Try to collect diff for merge request.
        diffs = compare_result.diffs

        if diffs.present?
          merge_request.compare_diffs = diffs

        elsif diffs == false
          # satellite timeout return false
          merge_request.can_be_created = false
          merge_request.compare_failed = true
        end
      else
        merge_request.can_be_created = false
        merge_request.compare_failed = false
      end

      commits = merge_request.compare_commits
      if commits && commits.count == 1
        commit = commits.first
        merge_request.title       = commit.title
        merge_request.description = commit.description.try(:strip)
      else
        merge_request.title = merge_request.source_branch.titleize.humanize
      end

      merge_request

    rescue Gitlab::Satellite::BranchesWithoutParent
      return build_failed(merge_request, "Selected branches have no common commit so they cannot be merged.")
    end

    def build_failed(merge_request, message)
      merge_request.errors.add(:base, message) unless message.nil?
      merge_request.compare_commits = []
      merge_request.can_be_created = false
      merge_request
    end
  end
end
