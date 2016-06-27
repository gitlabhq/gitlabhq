module MergeRequests
  class BuildService < MergeRequests::BaseService
    def execute
      merge_request = MergeRequest.new(params)

      # Set MR attributes
      merge_request.can_be_created = false
      merge_request.compare_commits = []
      merge_request.source_project = project unless merge_request.source_project

      merge_request.target_project = nil unless can?(current_user, :read_project, merge_request.target_project)

      merge_request.target_project ||= (project.forked_from_project || project)
      merge_request.target_branch ||= merge_request.target_project.default_branch

      if merge_request.target_branch.blank? || merge_request.source_branch.blank?
        message =
          if params[:source_branch] || params[:target_branch]
            "You must select source and target branch"
          end

        return build_failed(merge_request, message)
      end

      compare = CompareService.new.execute(
        merge_request.source_project,
        merge_request.source_branch,
        merge_request.target_project,
        merge_request.target_branch,
      )

      commits = compare.commits

      # At this point we decide if merge request can be created
      # If we have at least one commit to merge -> creation allowed
      if commits.present?
        merge_request.compare_commits = Commit.decorate(commits, merge_request.source_project)
        merge_request.can_be_created = true
        merge_request.compare = compare
      else
        merge_request.can_be_created = false
      end

      set_title_and_description(merge_request)
    end

    private

    # When your branch name starts with an iid followed by a dash this pattern will be
    # interpreted as the user wants to close that issue on this project.
    #
    # For example:
    # - Issue 112 exists, title: Emoji don't show up in commit title
    # - Source branch is: 112-fix-mep-mep
    #
    # Will lead to:
    # - Appending `Closes #112` to the description
    # - Setting the title as 'Resolves "Emoji don't show up in commit title"' if there is
    #   more than one commit in the MR
    #
    def set_title_and_description(merge_request)
      if match = merge_request.source_branch.match(/\A(\d+)-/)
        iid = match[1]
      end

      commits = merge_request.compare_commits
      if commits && commits.count == 1
        commit = commits.first
        merge_request.title = commit.title
        merge_request.description ||= commit.description.try(:strip)
      elsif iid && (issue = merge_request.target_project.get_issue(iid)) && !issue.try(:confidential?)
        case issue
        when Issue
          merge_request.title = "Resolve \"#{issue.title}\""
        when ExternalIssue
          merge_request.title = "Resolve #{issue.title}"
        end
      else
        merge_request.title = merge_request.source_branch.titleize.humanize
      end

      # Set MR description based on project template
      if merge_request.target_project.merge_requests_template.present?
        merge_request.description = merge_request.target_project.merge_requests_template
      end

      if iid
        closes_issue = "Closes ##{iid}"

        if merge_request.description.present?
          merge_request.description += closes_issue.prepend("\n")
        else
          merge_request.description = closes_issue
        end
      end

      merge_request
    end

    def build_failed(merge_request, message)
      merge_request.errors.add(:base, message) unless message.nil?
      merge_request.compare_commits = []
      merge_request.can_be_created = false
      merge_request
    end
  end
end
