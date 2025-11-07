# frozen_string_literal: true

get '/o', to: 'organizations/organizations#index', as: 'organizations_scope'

scope(
  path: '/o/:organization_path',
  constraints: { organization_path: Gitlab::PathRegex.organization_route_regex },
  as: :organization
) do
  root 'root#index'

  resources :projects, only: [:new, :create]
  resources :groups, only: [:new, :create]

  resource :dashboard, controller: 'dashboard', only: [] do
    scope module: :dashboard do
      resources :projects, only: [:index] do
        collection do
          get :contributed, :starred, :personal, :member, :inactive, to: 'projects#index'
        end
      end

      resources :groups, only: [:index] do
        collection do
          get :member, :inactive, to: 'groups#index'
        end
      end
    end

    root to: "dashboard/projects#index"
  end

  scope :emails, path: 'emails', as: :email do
    resource :confirmation, only: %i[new show create]
  end

  devise_scope :user do
    scope :user, path: 'users', as: :user do
      resource :confirmation, only: %i[new show create]
      resource :password, only: %i[new edit update create]
      resource :unlock, only: %i[new show create], controller: 'devise/unlocks'
    end
  end
end

scope path: '-' do
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

      resource :groups, only: [:new, :create, :destroy], as: :groups_organization

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
