module EE
  module ProjectsController
    extend ::Gitlab::Utils::Override

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
        merge_requests_template
        disable_overriding_approvers_per_merge_request
        repository_size_limit
        reset_approvals_on_push
        service_desk_enabled
        mirror
        mirror_trigger_builds
        mirror_user_id
        external_authorization_classification_label
        ci_cd_only
      ]
    end

    override :custom_import_params
    def custom_import_params
      custom_params = super
      ci_cd_param   = params.dig(:project, :ci_cd_only) || params[:ci_cd_only]

      custom_params[:ci_cd_only] = ci_cd_param if ci_cd_param == 'true'
      custom_params
    end

    override :active_new_project_tab
    def active_new_project_tab
      project_params[:ci_cd_only] == 'true' ? 'ci_cd_only' : super
    end
  end
end
