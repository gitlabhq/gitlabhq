# frozen_string_literal: true

module NamespacesHelper
  def namespace_id_from(params)
    params.dig(:project, :namespace_id) || params[:namespace_id]
  end

  def cascading_namespace_settings_popover_data(attribute, group, settings_path_helper)
    locked_by_ancestor = group.namespace_settings.public_send("#{attribute}_locked_by_ancestor?") # rubocop:disable GitlabSecurity/PublicSend

    popover_data = {
      locked_by_application_setting: group.namespace_settings.public_send("#{attribute}_locked_by_application_setting?"), # rubocop:disable GitlabSecurity/PublicSend
      locked_by_ancestor: locked_by_ancestor
    }

    if locked_by_ancestor
      ancestor_namespace = group.namespace_settings.public_send("#{attribute}_locked_ancestor").namespace # rubocop:disable GitlabSecurity/PublicSend

      popover_data[:ancestor_namespace] = {
        full_name: ancestor_namespace.full_name,
        path: settings_path_helper.call(ancestor_namespace)
      }
    end

    {
      popover_data: popover_data.to_json,
      testid: 'cascading-settings-lock-icon'
    }
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
      namespace_path: namespace.full_path,
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
end

NamespacesHelper.prepend_mod_with('NamespacesHelper')
