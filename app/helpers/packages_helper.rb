# frozen_string_literal: true

module PackagesHelper
  def package_sort_path(options = {})
    "#{request.path}?#{options.to_param}"
  end

  def nuget_package_registry_url(project_id)
    expose_url(api_v4_projects_packages_nuget_index_path(id: project_id, format: '.json'))
  end

  def package_registry_instance_url(registry_type)
    expose_url("api/#{::API::API.version}/packages/#{registry_type}")
  end

  def package_registry_project_url(project_id, registry_type = :maven)
    project_api_path = expose_path(api_v4_projects_path(id: project_id))
    package_registry_project_path = "#{project_api_path}/packages/#{registry_type}"
    expose_url(package_registry_project_path)
  end

  def package_from_presenter(package)
    presenter = ::Packages::Detail::PackagePresenter.new(package)

    presenter.detail_view.to_json
  end

  def pypi_registry_url(project_id)
    full_url = expose_url(api_v4_projects_packages_pypi_simple_package_name_path({ id: project_id, package_name: '' }, true))
    full_url.sub!('://', '://__token__:<your_personal_token>@')
  end

  def composer_registry_url(group_id)
    expose_url(api_v4_group___packages_composer_packages_path(id: group_id, format: '.json'))
  end

  def composer_config_repository_name(group_id)
    "#{Gitlab.config.gitlab.host}/#{group_id}"
  end

  def packages_list_data(type, resource)
    {
      resource_id: resource.id,
      page_type: type,
      empty_list_help_url: help_page_path('user/packages/package_registry/index'),
      empty_list_illustration: image_path('illustrations/no-packages.svg'),
      package_help_url: help_page_path('user/packages/index')
    }
  end

  def track_package_event(event_name, scope, **args)
    ::Packages::CreateEventService.new(nil, current_user, event_name: event_name, scope: scope).execute
    category = args.delete(:category) || self.class.name
    ::Gitlab::Tracking.event(category, event_name.to_s, **args)
  end

  def show_cleanup_policy_on_alert(project)
    Gitlab.com? &&
    Gitlab.config.registry.enabled &&
    project.container_registry_enabled &&
    !Gitlab::CurrentSettings.container_expiration_policies_enable_historic_entries &&
    Feature.enabled?(:container_expiration_policies_historic_entry, project) &&
    project.container_expiration_policy.nil? &&
    project.container_repositories.exists?
  end

  def package_details_data(project, package = nil)
    {
      package: package ? package_from_presenter(package) : nil,
      can_delete: can?(current_user, :destroy_package, project).to_s,
      svg_path: image_path('illustrations/no-packages.svg'),
      npm_path: package_registry_instance_url(:npm),
      npm_help_path: help_page_path('user/packages/npm_registry/index'),
      maven_path: package_registry_project_url(project.id, :maven),
      maven_help_path: help_page_path('user/packages/maven_repository/index'),
      conan_path: package_registry_project_url(project.id, :conan),
      conan_help_path: help_page_path('user/packages/conan_repository/index'),
      nuget_path: nuget_package_registry_url(project.id),
      nuget_help_path: help_page_path('user/packages/nuget_repository/index'),
      pypi_path: pypi_registry_url(project.id),
      pypi_setup_path: package_registry_project_url(project.id, :pypi),
      pypi_help_path: help_page_path('user/packages/pypi_repository/index'),
      composer_path: composer_registry_url(project&.group&.id),
      composer_help_path: help_page_path('user/packages/composer_repository/index'),
      project_name: project.name,
      project_list_url: project_packages_path(project),
      group_list_url: project.group ? group_packages_path(project.group) : '',
      composer_config_repository_name: composer_config_repository_name(project.group&.id)
    }
  end
end
