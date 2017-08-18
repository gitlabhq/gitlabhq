module MergeRequests
  class CreateFromIssueService < MergeRequests::CreateService
    def execute
      return error('Invalid issue iid') unless issue_iid.present? && issue.present?

      result = CreateBranchService.new(project, current_user).execute(branch_name, ref)
      return result if result[:status] == :error

      SystemNoteService.new_issue_branch(issue, project, current_user, branch_name)

      new_merge_request = create(merge_request)

      if new_merge_request.valid?
        success(new_merge_request)
      else
        error(new_merge_request.errors)
      end
    end

    private

    def issue_iid
      @isssue_iid ||= params.delete(:issue_iid)
    end

    def issue
      @issue ||= IssuesFinder.new(current_user, project_id: project.id).find_by(iid: issue_iid)
    end

    def branch_name
      @branch_name ||= issue.to_branch_name
    end

    def ref
      project.default_branch || 'master'
    end

    def merge_request
      MergeRequests::BuildService.new(project, current_user, merge_request_params).execute
    end

    def merge_request_params
      {
        source_project_id: project.id,
        source_branch: branch_name,
        target_project_id: project.id
      }
    end

    def success(merge_request)
      super().merge(merge_request: merge_request)
    end
  end
end
