# frozen_string_literal: true

# Skip creating organization scoped versions of these
# See https://gitlab.com/gitlab-org/gitlab/-/blob/d2272513eabc62b1342e4d9f0d775f7c1764eae0/config/routes.rb#L412
unless @organization_scoped_routes
  resources(
    :organizations,
    path: 'o',
    param: :organization_path,
    constraints: {
      organization_path: Gitlab::PathRegex.organization_route_regex
    },
    only: [:new],
    module: :organizations
  ) do
    collection do
      get '/', action: :index, format: false

      scope(path: '-') do
        post :preview_markdown
      end
    end

    member do
      scope(path: '-') do
        get :overview, action: :show, as: ''
        get :activity
        get :groups_and_projects
        get :users

        resource :settings, only: [], as: :settings_organization do
          get :general
        end

        resource :groups, only: [:new, :create, :destroy], as: :groups_organization

        resources :artifact_registry, only: [:index], as: :artifact_registry_organization

        scope(
          path: 'groups/*id',
          constraints: { id: Gitlab::PathRegex.full_namespace_route_regex }
        ) do
          resource(
            :groups,
            path: '/',
            only: [:edit],
            as: :groups_organization
          )
        end

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
  end
end
