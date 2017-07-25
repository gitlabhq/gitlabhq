module EE
  module ProjectsController
    def project_params_attributes
      attrs = super + project_params_ee
      attrs += repository_mirrors_params if project&.feature_available?(:repository_mirrors)

      attrs
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
      ]
    end

    def repository_mirrors_params
      %i[
        mirror
        mirror_trigger_builds
        mirror_user_id
      ]
    end
  end
end
