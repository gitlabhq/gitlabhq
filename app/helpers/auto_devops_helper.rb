# frozen_string_literal: true

module AutoDevopsHelper
  def badge_for_auto_devops_scope(auto_devops_receiver)
    return unless auto_devops_receiver.auto_devops_enabled?

    case auto_devops_receiver.first_auto_devops_config[:scope]
    when :project
      nil
    when :group
      s_('CICD|group enabled')
    when :instance
      s_('CICD|instance enabled')
    end
  end

  def auto_devops_settings_path(project)
    project_settings_ci_cd_path(project, anchor: 'autodevops-settings')
  end
end
