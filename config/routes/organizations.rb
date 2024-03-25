# frozen_string_literal: true

resources(:organizations, only: [:show, :index, :new], param: :organization_path, module: :organizations) do
  collection do
    post :preview_markdown
  end

  member do
    get :activity
    get :groups_and_projects
    get :users

    resource :settings, only: [], as: :settings_organization do
      get :general
    end

    resource :groups, only: [:new], as: :groups_organization

    scope(
      path: 'projects/*namespace_id',
      as: :namespace,
      constraints: { namespace_id: Gitlab::PathRegex.full_namespace_route_regex }
    ) do
      resources(
        :projects,
        path: '/',
        constraints: { id: Gitlab::PathRegex.project_route_regex },
        only: [:edit],
        as: :projects_organization
      )
    end
  end
end
