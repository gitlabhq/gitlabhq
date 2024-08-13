# frozen_string_literal: true

module Projects::TerraformHelper
  def js_terraform_list_data(current_user, project)
    {
      empty_state_image: image_path('illustrations/empty-state/empty-environment-md.svg'),
      project_path: project.full_path,
      terraform_admin: current_user&.can?(:admin_terraform_state, project),
      access_tokens_path: user_settings_personal_access_tokens_path,
      username: current_user&.username,
      terraform_api_url: "#{Settings.gitlab.url}/api/v4/projects/#{project.id}/terraform/state"
    }
  end

  def show_period_in_terraform_state_name_alert?(project)
    return false unless show_period_in_terraform_state_name_alert_callout?

    project.terraform_states.exists?
  end
end
