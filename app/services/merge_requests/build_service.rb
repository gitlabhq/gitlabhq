# frozen_string_literal: true

module MergeRequests
  class BuildService < MergeRequests::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      @params_issue_iid = params.delete(:issue_iid)
      self.merge_request = MergeRequest.new
      # TODO: this should handle all quick actions that don't have side effects
      # https://gitlab.com/gitlab-org/gitlab-foss/issues/53658
      merge_quick_actions_into_params!(merge_request, only: [:target_branch])

      # Assign the projects first so we can use policies for `filter_params`
      merge_request.author = current_user
      merge_request.source_project = find_source_project
      merge_request.target_project = find_target_project

      process_params

      merge_request.compare_commits = []
      set_merge_request_target_branch

      merge_request.can_be_created = projects_and_branches_valid?

      # compare branches only if branches are valid, otherwise
      # compare_branches may raise an error
      if merge_request.can_be_created
        compare_branches
        assign_title_and_description
        assign_labels
        assign_milestone
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
             :first_multiline_commit,
             :errors,
             to: :merge_request

    def force_remove_source_branch
      if params.key?(:force_remove_source_branch)
        params.delete(:force_remove_source_branch)
      else
        merge_request.source_project.remove_source_branch_after_merge?
      end
    end

    def filter_id_params
      # merge_request.assign_attributes(...) below is a Rails
      # method that only work if all the params it is passed have
      # corresponding fields in the database. As there are no fields
      # in the database for :add_label_ids, :remove_label_ids,
      # :add_assignee_ids and :remove_assignee_ids, we
      # need to remove them from the params before the call to
      # merge_request.assign_attributes(...)
      #
      # IssuableBaseService#process_label_ids and
      # IssuableBaseService#process_assignee_ids take care
      # of the removal.
      params[:label_ids] = process_label_ids(params, extra_label_ids: merge_request.label_ids.to_a)

      params[:assignee_ids] = process_assignee_ids(params, extra_assignee_ids: merge_request.assignee_ids.to_a)

      merge_request.assign_attributes(params.to_h.compact)
    end

    def process_params
      # Force remove the source branch?
      merge_request.merge_params['force_remove_source_branch'] = force_remove_source_branch

      # Only assign merge requests params that are allowed
      self.params = assign_allowed_merge_params(merge_request, params)

      # Filter out params that are either not allowed or invalid
      filter_params(merge_request)

      # Filter out the following from params:
      #  - :add_label_ids and :remove_label_ids
      #  - :add_assignee_ids and :remove_assignee_ids
      filter_id_params
    end

    def find_source_project
      source_project = project_from_params(:source_project)
      return source_project if source_project.present? && can?(current_user, :create_merge_request_from, source_project)

      project
    end

    def find_target_project
      target_project = project_from_params(:target_project)
      return target_project if target_project.present? && can?(current_user, :create_merge_request_in, target_project)

      target_project = project.default_merge_request_target

      return target_project if target_project.present? && can?(current_user, :create_merge_request_in, target_project)

      project
    end

    def project_from_params(param_name)
      project_from_params = params.delete(param_name)

      id_param_name = :"#{param_name}_id"
      if project_from_params.nil? && params[id_param_name]
        project_from_params = Project.find_by_id(params.delete(id_param_name))
      end

      project_from_params
    end

    def set_merge_request_target_branch
      if source_branch_default? && !target_branch_specified?
        merge_request.target_branch = nil
      else
        merge_request.target_branch ||= target_project.default_branch
      end
    end

    def source_branch_specified?
      params[:source_branch].present?
    end

    def target_branch_specified?
      params[:target_branch].present?
    end

    def projects_and_branches_valid?
      return false if source_project.nil? || target_project.nil?
      return false unless source_branch_specified? || target_branch_specified?

      validate_projects_and_branches
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

    def validate_projects_and_branches
      merge_request.validate_target_project
      merge_request.validate_fork

      return if errors.any?

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
      same_source_and_target_project? && target_branch == source_branch
    end

    def source_branch_default?
      same_source_and_target_project? && source_branch == target_project.default_branch
    end

    def same_source_and_target_project?
      source_project == target_project
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
    # - Issue 112 exists
    # - title: Emoji don't show up in commit title
    # - Source branch is: 112-fix-mep-mep
    #
    # Will lead to:
    # - Appending `Closes #112` to the description
    # - Setting the title as 'Resolves "Emoji don't show up in commit title"' if there is
    #   more than one commit in the MR
    #
    def assign_title_and_description
      assign_title_and_description_from_commits
      merge_request.title ||= title_from_issue if target_project.issues_enabled? || target_project.external_issue_tracker
      merge_request.title ||= source_branch.titleize.humanize
      merge_request.title = wip_title if compare_commits.empty?

      append_closes_description
    end

    def assign_labels
      return unless target_project.issues_enabled? && issue
      return if merge_request.label_ids&.any?

      merge_request.label_ids = issue.try(:label_ids)
    end

    def assign_milestone
      return unless target_project.issues_enabled? && issue
      return if merge_request.milestone_id.present?

      merge_request.milestone_id = issue.try(:milestone_id)
    end

    def append_closes_description
      return unless issue&.to_reference.present?

      closes_issue = "#{target_project.autoclose_referenced_issues ? 'Closes' : 'Related to'} #{issue.to_reference}"

      if description.present?
        descr_parts = [merge_request.description, closes_issue]
        merge_request.description = descr_parts.join("\n\n")
      else
        merge_request.description = closes_issue
      end
    end

    def assign_title_and_description_from_commits
      commits = compare_commits

      if commits&.count == 1
        commit = commits.first
      else
        commit = first_multiline_commit
        return unless commit
      end

      merge_request.title ||= commit.title
      merge_request.description ||= commit.description.try(:strip)
    end

    def title_from_issue
      return unless issue

      return "Resolve \"#{issue.title}\"" if issue.is_a?(Issue)

      return if issue_iid.blank?

      title_parts = ["Resolve #{issue.to_reference}"]
      branch_title = source_branch.downcase.remove(issue_iid.downcase).titleize.humanize

      title_parts << "\"#{branch_title}\"" if branch_title.present?
      title_parts.join(' ')
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
      strong_memoize(:issue) do
        target_project.get_issue(issue_iid, current_user)
      end
    end
  end
end

MergeRequests::BuildService.prepend_mod_with('MergeRequests::BuildService')
