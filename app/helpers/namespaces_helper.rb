# frozen_string_literal: true

module NamespacesHelper
  def namespace_id_from(params)
    params.dig(:project, :namespace_id) || params[:namespace_id]
  end

  def check_group_lock(group, method)
    if group.namespace_settings.respond_to?(method)
      group.namespace_settings.public_send(method) # rubocop:disable GitlabSecurity/PublicSend
    else
      false
    end
  end

  def check_project_lock(project, method)
    if project.project_setting.respond_to?(method)
      project.project_setting.public_send(method) # rubocop:disable GitlabSecurity/PublicSend
    else
      false
    end
  end

  def cascading_namespace_settings_tooltip_data(attribute, group, settings_path_helper)
    {
      tooltip_data: cascading_namespace_settings_tooltip_raw_data(attribute, group, settings_path_helper).to_json,
      testid: 'cascading-settings-lock-icon'
    }
  end

  def cascading_namespace_settings_tooltip_raw_data(attribute, group, settings_path_helper)
    return {} if group.nil?

    locked_by_ancestor = check_group_lock(group, "#{attribute}_locked_by_ancestor?")
    locked_by_application = check_group_lock(group, "#{attribute}_locked_by_application_setting?")

    tooltip_data = {
      locked_by_application_setting: locked_by_application,
      locked_by_ancestor: locked_by_ancestor
    }

    if locked_by_ancestor
      ancestor_namespace = group.namespace_settings&.public_send("#{attribute}_locked_ancestor")&.namespace # rubocop:disable GitlabSecurity/PublicSend

      if ancestor_namespace
        tooltip_data[:ancestor_namespace] = {
          full_name: ancestor_namespace.full_name,
          path: settings_path_helper.call(ancestor_namespace)
        }
      end
    end

    tooltip_data
  end

  def project_cascading_namespace_settings_tooltip_data(attribute, project, settings_path_helper)
    return unless attribute && project && settings_path_helper

    data = cascading_namespace_settings_tooltip_raw_data(attribute, project.parent, settings_path_helper)
    return data if data[:locked_by_ancestor]

    data[:locked_by_application_setting] = check_project_lock(project, "#{attribute}_locked_by_application_setting?")
    locked_by_ancestor = check_project_lock(project, "#{attribute}_locked_by_ancestor?")
    locked_by_project = check_project_lock(project, "#{attribute}_locked?")

    return data unless locked_by_ancestor || locked_by_project

    data[:locked_by_ancestor] = true
    data[:ancestor_namespace] = {
      full_name: project.parent.name,
      path: Gitlab::UrlBuilder.build(project.parent, only_path: true)
    }

    data
  end

  def cascading_namespace_setting_locked?(attribute, group, **args)
    return false if group.nil?

    method_name = "#{attribute}_locked?"
    return false unless group.namespace_settings.respond_to?(method_name)

    group.namespace_settings.public_send(method_name, **args) # rubocop:disable GitlabSecurity/PublicSend
  end

  def pipeline_usage_app_data(namespace)
    {
      namespace_actual_plan_name: namespace.actual_plan_name,
      namespace_id: namespace.id,
      user_namespace: namespace.user_namespace?.to_s,
      page_size: page_size
    }
  end

  def storage_usage_app_data(namespace)
    {
      namespace_id: namespace.id,
      namespace_path: namespace.full_path,
      user_namespace: namespace.user_namespace?.to_s,
      default_per_page: page_size
    }
  end

  def group_usage_quotas_url(group, *args)
    Rails.application.routes.url_helpers.group_usage_quotas_url(group.root_ancestor, *args)
  end
end

NamespacesHelper.prepend_mod_with('NamespacesHelper')
