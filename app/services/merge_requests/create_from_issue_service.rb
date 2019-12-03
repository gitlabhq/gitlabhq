# frozen_string_literal: true

module MergeRequests
  class CreateFromIssueService < MergeRequests::CreateService
    def initialize(project, user, params)
      # branch - the name of new branch
      # ref    - the source of new branch.

      @branch_name       = params[:branch_name]
      @issue_iid         = params[:issue_iid]
      @ref               = params[:ref]
      @target_project_id = params[:target_project_id]

      super(project, user)
    end

    def execute
      return error('Project not found') if target_project.blank?
      return error('Not allowed to create merge request') unless can_create_merge_request?
      return error('Invalid issue iid') unless @issue_iid.present? && issue.present?

      result = ::Branches::CreateService.new(target_project, current_user).execute(branch_name, ref)
      return result if result[:status] == :error

      new_merge_request = create(merge_request)

      if new_merge_request.valid?
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
      target_project.default_branch || 'master'
    end

    def merge_request
      MergeRequests::BuildService.new(target_project, current_user, merge_request_params).execute
    end

    def merge_request_params
      {
        issue_iid: @issue_iid,
        source_project_id: target_project.id,
        source_branch: branch_name,
        target_project_id: target_project.id,
        target_branch: target_branch
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
