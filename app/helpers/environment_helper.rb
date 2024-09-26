# frozen_string_literal: true

module EnvironmentHelper
  def deployment_path(deployment)
    [deployment.project, deployment.deployable]
  end

  def deployment_link(deployment, text: nil)
    return unless deployment

    link_label = text || "##{deployment.iid}"

    link_to link_label, deployment_path(deployment)
  end

  def environments_detail_data(user, project, environment)
    {
      name: environment.name,
      id: environment.id,
      project_full_path: project.full_path,
      base_path: project_environment_path(project, environment),
      external_url: environment.external_url,
      can_update_environment: can?(current_user, :update_environment, environment),
      can_destroy_environment: can_destroy_environment?(environment),
      can_stop_environment: can?(current_user, :stop_environment, environment),
      can_admin_environment: can?(current_user, :admin_environment, project),
      environments_fetch_path: project_environments_path(project, format: :json),
      environment_edit_path: edit_project_environment_path(project, environment),
      environment_stop_path: stop_project_environment_path(project, environment),
      environment_delete_path: environment_delete_path(environment),
      environment_cancel_auto_stop_path: cancel_auto_stop_project_environment_path(project, environment),
      environment_terminal_path: terminal_project_environment_path(project, environment),
      has_terminals: environment.has_terminals?,
      is_environment_available: environment.available?,
      description_html: markdown_field(environment, :description),
      auto_stop_at: environment.auto_stop_at,
      graphql_etag_key: environment.etag_cache_key
    }
  end

  def environments_detail_data_json(user, project, environment)
    environments_detail_data(user, project, environment).to_json
  end
end
