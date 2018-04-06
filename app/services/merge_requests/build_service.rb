module MergeRequests
  class BuildService < MergeRequests::BaseService
    prepend EE::MergeRequests::BuildService
    include Gitlab::Utils::StrongMemoize

    def execute
      @params_issue_iid = params.delete(:issue_iid)

      self.merge_request = MergeRequest.new(params)
      merge_request.author = current_user
      merge_request.compare_commits = []
      merge_request.source_project  = find_source_project
      merge_request.target_project  = find_target_project
      merge_request.target_branch   = find_target_branch
      merge_request.can_be_created  = branches_valid?

      # compare branches only if branches are valid, otherwise
      # compare_branches may raise an error
      if merge_request.can_be_created
        compare_branches
        assign_title_and_description
      end

      merge_request
    end

    private

    attr_accessor :merge_request

    delegate :target_branch,
             :target_branch_ref,
             :target_project,
             :source_branch,
             :source_branch_ref,
             :source_project,
             :compare_commits,
             :wip_title,
             :description,
             :errors,
             to: :merge_request

    def find_source_project
      return source_project if source_project.present? && can?(current_user, :read_project, source_project)

      project
    end

    def find_target_project
      return target_project if target_project.present? && can?(current_user, :read_project, target_project)

      project.default_merge_request_target
    end

    def find_target_branch
      target_branch || target_project.default_branch
    end

    def source_branch_specified?
      params[:source_branch].present?
    end

    def target_branch_specified?
      params[:target_branch].present?
    end

    def branches_valid?
      return false unless source_branch_specified? || target_branch_specified?

      validate_branches
      errors.blank?
    end

    def compare_branches
      compare = CompareService.new(
        source_project,
        source_branch_ref
      ).execute(
        target_project,
        target_branch_ref
      )

      if compare
        merge_request.compare_commits = compare.commits
        merge_request.compare = compare
      end
    end

    def validate_branches
      add_error('You must select source and target branch') unless branches_present?
      add_error('You must select different branches') if same_source_and_target?
      add_error("Source branch \"#{source_branch}\" does not exist") unless source_branch_exists?
      add_error("Target branch \"#{target_branch}\" does not exist") unless target_branch_exists?
    end

    def add_error(message)
      errors.add(:base, message)
    end

    def branches_present?
      target_branch.present? && source_branch.present?
    end

    def same_source_and_target?
      source_project == target_project && target_branch == source_branch
    end

    def source_branch_exists?
      source_branch.blank? || source_project.commit(source_branch)
    end

    def target_branch_exists?
      target_branch.blank? || target_project.commit(target_branch)
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
    def assign_title_and_description
      assign_title_and_description_from_single_commit
      assign_title_from_issue if target_project.issues_enabled? || target_project.external_issue_tracker

      merge_request.title ||= source_branch.titleize.humanize
      merge_request.title = wip_title if compare_commits.empty?

      append_closes_description
    end

    def append_closes_description
      return unless issue&.to_reference.present?

      closes_issue = "Closes #{issue.to_reference}"

      if description.present?
        merge_request.description += closes_issue.prepend("\n\n")
      else
        merge_request.description = closes_issue
      end
    end

    def assign_title_and_description_from_single_commit
      commits = compare_commits

      return unless commits&.count == 1

      commit = commits.first
      merge_request.title ||= commit.title
      merge_request.description ||= commit.description.try(:strip)
    end

    def assign_title_from_issue
      return unless issue

      merge_request.title = "Resolve \"#{issue.title}\"" if issue.is_a?(Issue)

      return if merge_request.title.present?

      if issue_iid.present?
        merge_request.title = "Resolve #{issue.to_reference}"
        branch_title = source_branch.downcase.remove(issue_iid.downcase).titleize.humanize
        merge_request.title += " \"#{branch_title}\"" if branch_title.present?
      end
    end

    def issue_iid
      strong_memoize(:issue_iid) do
        @params_issue_iid || begin
          id = if target_project.external_issue_tracker
                 source_branch.match(target_project.external_issue_reference_pattern).try(:[], 0)
               end

          id || source_branch.match(/\A(\d+)-/).try(:[], 1)
        end
      end
    end

    def issue
      @issue ||= target_project.get_issue(issue_iid, current_user)
    end
  end
end
