# frozen_string_literal: true

module PackagesHelper
  include ::API::Helpers::RelatedResourcesHelpers

  def nuget_package_registry_url(project_id)
    expose_url(api_v4_projects_packages_nuget_index_path(id: project_id, format: '.json'))
  end

  def package_registry_instance_url(registry_type)
    expose_url("api/#{::API::API.version}/packages/#{registry_type}")
  end

  def package_registry_project_url(project_id, registry_type = :maven)
    project_api_path = api_v4_projects_path(id: project_id)
    package_registry_project_path = "#{project_api_path}/packages/#{registry_type}"
    expose_url(package_registry_project_path)
  end

  def package_from_presenter(package)
    presenter = ::Packages::Detail::PackagePresenter.new(package)

    presenter.detail_view.to_json
  end

  def pypi_registry_url(project)
    full_url = expose_url(
      api_v4_projects_packages_pypi_simple_package_name_path(
        { id: project.id, package_name: '' },
        true
      )
    )

    if project.project_feature.public_packages?
      full_url
    else
      full_url.sub!('://', '://__token__:<your_personal_token>@')
    end
  end

  def composer_registry_url(group_id)
    expose_url(api_v4_group___packages_composer_packages_path(id: group_id, format: '.json'))
  end

  def composer_config_repository_name(group_id)
    "#{Gitlab.config.gitlab.host}/#{group_id}"
  end

  def track_package_event(event_name, scope, **args)
    ::Packages::CreateEventService.new(args[:project], current_user, event_name: event_name, scope: scope).execute
    category = args.delete(:category) || self.class.name
    ::Gitlab::Tracking.event(category, event_name.to_s, **args)
  end

  def show_cleanup_policy_link(project)
    show_container_registry_settings(project) &&
      project.feature_available?(:container_registry, current_user) &&
      project.container_repositories.exists? &&
      !project.container_expiration_policy&.enabled
  end

  def show_container_registry_settings(project)
    Gitlab.config.registry.enabled &&
      Ability.allowed?(current_user, :admin_container_image, project)
  end

  def show_package_registry_settings(project)
    Gitlab.config.packages.enabled &&
      Ability.allowed?(current_user, :admin_package, project)
  end

  def show_group_package_registry_settings(group)
    group.packages_feature_enabled? &&
      Ability.allowed?(current_user, :admin_group, group)
  end

  def can_delete_packages?(project)
    Gitlab.config.packages.enabled &&
      Ability.allowed?(current_user, :destroy_package, project)
  end

  def can_delete_group_packages?(group)
    group.packages_feature_enabled? &&
      Ability.allowed?(current_user, :destroy_package, group)
  end

  def group_packages_template_data(group)
    packages_template_data.merge({
      can_delete_packages: can_delete_group_packages?(group).to_s,
      endpoint: group_packages_path(group),
      full_path: group.full_path,
      group_list_url: group_packages_path(group),
      page_type: 'groups',

      settings_path: if show_group_package_registry_settings(group)
                       group_settings_packages_and_registries_path(group)
                     else
                       ''
                     end
    })
  end

  def project_packages_template_data(project)
    packages_template_data.merge({
      can_delete_packages: can_delete_packages?(project).to_s,
      endpoint: project_packages_path(project),
      full_path: project.full_path,
      page_type: 'projects',
      project_list_url: project_packages_path(project),

      settings_path: if show_package_registry_settings(project)
                       project_settings_packages_and_registries_path(project, anchor: 'package-registry-settings')
                     else
                       ''
                     end
    })
  end

  def cleanup_settings_data(project)
    {
      project_id: project.id,
      project_path: project.full_path,
      cadence_options: cadence_options.to_json,
      keep_n_options: keep_n_options.to_json,
      older_than_options: older_than_options.to_json,
      is_admin: current_user&.admin.to_s,
      admin_settings_path: ci_cd_admin_application_settings_path(anchor: 'js-registry-settings'),
      project_settings_path: project_settings_packages_and_registries_path(project),
      enable_historic_entries: container_expiration_policies_historic_entry_enabled?.to_s,
      help_page_path: help_page_path(
        'user/packages/container_registry/reduce_container_registry_storage.md',
        anchor: 'cleanup-policy'
      ),
      show_cleanup_policy_link: show_cleanup_policy_link(project).to_s,
      tags_regex_help_page_path: help_page_path(
        'user/packages/container_registry/reduce_container_registry_storage.md',
        anchor: 'regex-pattern-examples'
      )
    }
  end

  def settings_data(project)
    cleanup_settings_data(project).merge(
      show_container_registry_settings: show_container_registry_settings(project).to_s,
      show_package_registry_settings: show_package_registry_settings(project).to_s,
      is_container_registry_metadata_database_enabled: (
        show_container_registry_settings(project) &&
          ContainerRegistry::GitlabApiClient.supports_gitlab_api?
      ).to_s,
      cleanup_settings_path: cleanup_image_tags_project_settings_packages_and_registries_path(project)
    )
  end

  private

  def packages_template_data
    {
      empty_list_illustration: image_path('illustrations/empty-state/empty-package-md.svg'),
      group_list_url: '',
      npm_instance_url: package_registry_instance_url(:npm),
      project_list_url: ''
    }
  end
end
