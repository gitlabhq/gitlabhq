module EE
  module ProjectsController
    def project_params_attributes
      super + project_params_ee
    end

    private

    def project_params_ee
      %i[
        approvals_before_merge
        approver_group_ids
        approver_ids
        issues_template
        merge_method
        merge_requests_template
        disable_overriding_approvers_per_merge_request
        repository_size_limit
        reset_approvals_on_push
        service_desk_enabled
        mirror
        mirror_trigger_builds
        mirror_user_id
      ]
    end
  end
end
