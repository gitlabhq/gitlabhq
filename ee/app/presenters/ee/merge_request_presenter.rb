module EE
  module MergeRequestPresenter
    def approvals_path
      if requires_approve?
        approvals_project_merge_request_path(project, merge_request)
      end
    end
  end
end
