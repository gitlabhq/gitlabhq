module MergeRequests
  class BuildService < MergeRequests::BaseService
    def execute
      @merge_request = merge_request = MergeRequest.new(params)

      # Set MR attributes
      merge_request.can_be_created = true
      merge_request.compare_commits = []
      merge_request.source_project = project unless merge_request.source_project

      merge_request.target_project = nil unless can?(current_user, :read_project, merge_request.target_project)

      merge_request.target_project ||= (project.forked_from_project || project)
      merge_request.target_branch ||= merge_request.target_project.default_branch

      messages = validate_branches(merge_request)
      return build_failed(merge_request, messages) unless messages.empty?

      compare = CompareService.new.execute(
        merge_request.source_project,
        merge_request.source_branch,
        merge_request.target_project,
        merge_request.target_branch,
      )

      merge_request.compare_commits = compare.commits
      merge_request.compare = compare

      set_title_and_description(merge_request)
    end

    private

    def validate_branches(merge_request)
      messages = []

      if merge_request.target_branch.blank? || merge_request.source_branch.blank?
        messages <<
          if params[:source_branch] || params[:target_branch]
            "You must select source and target branch"
          end
      end

      if merge_request.source_project == merge_request.target_project &&
          merge_request.target_branch == merge_request.source_branch

        messages << 'You must select different branches'
      end

      # See if source and target branches exist
      if merge_request.source_branch.present? && !merge_request.source_project.commit(merge_request.source_branch)
        messages << "Source branch \"#{merge_request.source_branch}\" does not exist"
      end

      if merge_request.target_branch.present? && !merge_request.target_project.commit(merge_request.target_branch)
        messages << "Target branch \"#{merge_request.target_branch}\" does not exist"
      end

      messages
    end

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

      # TODO: if single_commit? then set_title_from_commit,
            # elsif source_branch_starts_with_issue_id? then set_from_issue_with_closes,
            # else title_from_branch
      commits = merge_request.compare_commits
      if commits && commits.count == 1
        commit = commits.first
        merge_request.title = commit.title
        merge_request.description ||= commit.description.try(:strip)
      elsif iid_from_branch_name && issue = get_issue
        case issue
        when Issue
          merge_request.title = "Resolve \"#{issue.title}\""
        when ExternalIssue
          merge_request.title = "Resolve #{issue.title}"
        end
      else
        # TODO: ensure this is called for confidential issues even if branch name starts with a number
        merge_request.title = merge_request.source_branch.titleize.humanize
      end

      if iid_from_branch_name
        @merge_request.description = description_with_closes_reference
      end

      merge_request.title = merge_request.wip_title if commits.empty?

      merge_request
    end

    def build_failed(merge_request, messages)
      messages.compact.each do |message|
        merge_request.errors.add(:base, message)
      end
      merge_request.compare_commits = []
      merge_request.can_be_created = false
      merge_request
    end

    private
    def iid_from_branch_name
      @iid_from_branch_name ||= @merge_request.source_branch.match(/\A(\d+)-/).try!(:[], 1)
    end

    def description_with_closes_reference
      [@merge_request.description, "Closes ##{iid_from_branch_name}"].reject(&:blank?).join("\n\n")
    end

    def get_issue
      @merge_request.target_project.get_issue(iid_from_branch_name, current_user)
    end
  end
end
