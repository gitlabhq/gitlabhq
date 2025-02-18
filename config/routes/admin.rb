# frozen_string_literal: true

namespace :admin do
  resources :users, constraints: { id: %r{[a-zA-Z./0-9_\-]+} } do
    resources :keys, only: [:show, :destroy]
    resources :identities, except: [:show]
    resources :impersonation_tokens, only: [:index, :create] do
      member do
        put :revoke
        put :rotate
      end
    end

    member do
      get :projects
      get :keys
      put :block
      put :unblock
      put :ban
      put :unban
      put :deactivate
      put :activate
      put :unlock
      put :confirm
      put :approve
      put :trust
      put :untrust
      delete :reject
      post :impersonate
      patch :disable_two_factor
      delete 'remove/:email_id', action: 'remove_email', as: 'remove_email'
    end
  end

  resource :session, only: [:new, :create] do
    post 'destroy', action: :destroy, as: :destroy
  end

  resource :impersonation, only: :destroy

  resource :initial_setup, controller: :initial_setup, only: [:new, :update]

  resources :abuse_reports, only: [:index, :show, :update, :destroy] do
    member do
      put :moderate_user
    end
  end
  resources :gitaly_servers, only: [:index]

  resources :spam_logs, only: [:index, :destroy] do
    member do
      post :mark_as_ham
    end
  end

  resources :applications do
    put 'renew', on: :member
  end

  resources :groups, only: [:index, :new, :create]

  resources :organizations, only: [:index]

  scope(
    path: 'groups/*id',
    controller: :groups,
    constraints: { id: Gitlab::PathRegex.full_namespace_route_regex, format: /(html|json|atom)/ }
  ) do
    scope(as: :group) do
      put :members_update
      get :edit, action: :edit
      get '/', action: :show
      patch '/', action: :update
      put '/', action: :update
      delete '/', action: :destroy
    end
  end

  resources :topics, only: [:index, :new, :create, :edit, :update, :destroy] do
    resource :avatar, controller: 'topics/avatars', only: [:destroy]
    collection do
      post :preview_markdown
      post :merge
    end
  end

  resources :deploy_keys, only: [:index, :new, :create, :edit, :update, :destroy]

  resources :hooks, only: [:index, :create, :edit, :update, :destroy] do
    member do
      post :test
    end

    resources :hook_logs, only: [:show] do
      member do
        post :retry
      end
    end
  end

  resources :broadcast_messages, only: [:index, :edit, :create, :update, :destroy] do
    post :preview, on: :collection
  end

  get :instance_review, to: 'instance_review#index'

  resources :background_migrations, only: [:index, :show] do
    resources :batched_jobs, only: [:show]

    member do
      post :pause
      post :resume
      post :retry
    end
  end

  resource :health_check, controller: 'health_check', only: [:show]
  resource :background_jobs, controller: 'background_jobs', only: [:show]

  resource :system_info, controller: 'system_info', only: [:show]

  resources :projects, only: [:index]

  resources :usage_trends, only: :index
  resource :dev_ops_reports, controller: 'dev_ops_report', only: :show
  get 'dev_ops_report', to: redirect('admin/dev_ops_reports')
  resources :cohorts, only: :index

  scope(
    path: 'projects/*namespace_id',
    as: :namespace,
    constraints: { namespace_id: Gitlab::PathRegex.full_namespace_route_regex }
  ) do
    resources(
      :projects,
      path: '/',
      constraints: { id: Gitlab::PathRegex.project_route_regex },
      only: [:show, :destroy]
    ) do
      member do
        put :transfer
        post :repository_check
        get :edit, action: :edit
        get '/', action: :show
        patch '/', action: :update
        put '/', action: :update
      end

      resources :runner_projects, only: [:create, :destroy]
    end
  end

  resource :application_settings, only: :update do
    resources :integrations, only: [:edit, :update] do
      member do
        get :overrides
        put :test
        post :reset
      end
    end

    resource :slack, only: [:destroy] do
      get :slack_auth
    end

    get :usage_data
    put :reset_registration_token
    put :reset_health_check_token
    put :reset_error_tracking_access_token
    put :clear_repository_check_states
    match :general, :integrations, :repository, :ci_cd, :reporting, :metrics_and_profiling, :network, :preferences, :search, via: [:get, :patch]
    get :lets_encrypt_terms_of_service
    get :slack_app_manifest_download, format: :json
    get :slack_app_manifest_share

    resource :appearances, only: [:show, :create, :update], path: 'appearance', module: 'application_settings' do
      member do
        get :preview_sign_in
        delete :logo
        delete :pwa_icon
        delete :header_logos
        delete :favicon
      end
    end
  end

  resources :plan_limits, only: :create

  resources :labels

  resources :runners, only: [:index, :new, :show, :edit, :update, :destroy] do
    member do
      get :register
      post :resume
      post :pause
    end

    collection do
      get :tag_list, format: :json
      get :runner_setup_scripts, format: :json
    end
  end

  resources :jobs, only: :index do
    collection do
      post :cancel_all
    end
  end

  namespace :ci do
    resource :variables, only: [:show, :update]
  end

  concerns :clusterable

  get '/dashboard/stats', to: 'dashboard#stats'

  root to: 'dashboard#index'

  get :version_check, to: 'version_check#version_check'
end
