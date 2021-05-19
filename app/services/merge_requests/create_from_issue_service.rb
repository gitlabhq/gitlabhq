# frozen_string_literal: true

module MergeRequests
  class CreateFromIssueService < MergeRequests::CreateService
    # TODO: This constructor does not use the "params:" argument from the superclass,
    #   but instead has a custom "mr_params:" argument. This is because historically,
    #   prior to named arguments being introduced to the constructor, it never passed
    #   along the third positional argument when calling `super`.
    #   This should be changed, in order to be consistent (all subclasses should pass
    #   along all of the arguments to the superclass, otherwise it is probably not an
    #   "is a" relationship). However, we need to be sure that passing the params
    #   argument to `super` (especially target_project_id) will not cause any unexpected
    #   behavior in the superclass. Since the addition of the named arguments is
    #   intended to be a low-risk pure refactor, we will defer this fix
    #   to this follow-on issue:
    #   https://gitlab.com/gitlab-org/gitlab/-/issues/328726
    def initialize(project:, current_user:, mr_params: {})
      # branch - the name of new branch
      # ref    - the source of new branch.

      @branch_name       = mr_params[:branch_name]
      @issue_iid         = mr_params[:issue_iid]
      @ref               = mr_params[:ref]
      @target_project_id = mr_params[:target_project_id]

      super(project: project, current_user: current_user)
    end

    def execute
      return error('Project not found') if target_project.blank?
      return error('Not allowed to create merge request') unless can_create_merge_request?
      return error('Invalid issue iid') unless @issue_iid.present? && issue.present?

      result = ::Branches::CreateService.new(target_project, current_user).execute(branch_name, ref)
      return result if result[:status] == :error

      new_merge_request = create(merge_request)

      if new_merge_request.valid?
        merge_request_activity_counter.track_mr_create_from_issue(user: current_user)
        SystemNoteService.new_merge_request(issue, project, current_user, new_merge_request)

        success(new_merge_request)
      else
        SystemNoteService.new_issue_branch(issue, project, current_user, branch_name, branch_project: target_project)

        error(new_merge_request.errors)
      end
    end

    private

    def can_create_merge_request?
      can?(current_user, :create_merge_request_from, target_project)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def issue
      @issue ||= IssuesFinder.new(current_user, project_id: project.id).find_by(iid: @issue_iid)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def branch_name
      @branch ||= @branch_name || issue.to_branch_name
    end

    def ref
      if valid_ref?
        @ref
      else
        default_branch
      end
    end

    def valid_ref?
      ref_is_branch? || ref_is_tag?
    end

    def ref_is_branch?
      target_project.repository.branch_exists?(@ref)
    end

    def ref_is_tag?
      target_project.repository.tag_exists?(@ref)
    end

    def default_branch
      target_project.default_branch_or_main
    end

    def merge_request
      MergeRequests::BuildService.new(project: target_project, current_user: current_user, params: merge_request_params).execute
    end

    def merge_request_params
      {
        issue_iid: @issue_iid,
        source_project_id: target_project.id,
        source_branch: branch_name,
        target_project_id: target_project.id,
        target_branch: target_branch,
        assignee_ids: [current_user.id]
      }
    end

    def target_branch
      if ref_is_branch?
        @ref
      else
        default_branch
      end
    end

    def success(merge_request)
      super().merge(merge_request: merge_request)
    end

    def target_project
      @target_project ||=
        if @target_project_id.present?
          project.forks.find_by_id(@target_project_id)
        else
          project
        end
    end
  end
end
