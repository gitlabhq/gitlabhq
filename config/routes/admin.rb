namespace :admin do
  resources :users, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ } do
    resources :keys, only: [:show, :destroy]
    resources :identities, except: [:show]

    member do
      get :projects
      get :keys
      get :groups
      put :block
      put :unblock
      put :unlock
      put :confirm
      post :impersonate
      patch :disable_two_factor
      delete 'remove/:email_id', action: 'remove_email', as: 'remove_email'
    end
  end

  ## EE-specific
  resource :push_rule, only: [:show, :update]
  ## EE-specific

  resource :impersonation, only: :destroy

  resources :abuse_reports, only: [:index, :destroy]
  resources :spam_logs, only: [:index, :destroy] do
    member do
      post :mark_as_ham
    end
  end

  resources :applications

  resources :groups, constraints: { id: /[^\/]+/ } do
    member do
      put :members_update
    end
  end

  resources :deploy_keys, only: [:index, :new, :create, :destroy]

  resources :hooks, only: [:index, :create, :destroy] do
    get :test
  end

  resources :broadcast_messages, only: [:index, :edit, :create, :update, :destroy] do
    post :preview, on: :collection
  end

  resource :logs, only: [:show]
  resource :health_check, controller: 'health_check', only: [:show]
  resource :background_jobs, controller: 'background_jobs', only: [:show]

  ## EE-specific
  resource :email, only: [:show, :create]
  ## EE-specific

  resource :system_info, controller: 'system_info', only: [:show]
  resources :requests_profiles, only: [:index, :show], param: :name, constraints: { name: /.+\.html/ }

  resources :namespaces, path: '/projects', constraints: { id: /[a-zA-Z.0-9_\-]+/ }, only: [] do
    root to: 'projects#index', as: :projects

    resources(:projects,
              path: '/',
              constraints: { id: /[a-zA-Z.0-9_\-]+/ },
              only: [:index, :show]) do
      root to: 'projects#show'

      member do
        put :transfer
        post :repository_check
      end

      resources :runner_projects, only: [:create, :destroy]
    end
  end

  resource :appearances, only: [:show, :create, :update], path: 'appearance' do
    member do
      get :preview
      delete :logo
      delete :header_logos
    end
  end

  resource :application_settings, only: [:show, :update] do
    resources :services, only: [:index, :edit, :update]

    ## EE-specific
    get :usage_data
    ## EE-specific

    put :reset_runners_token
    put :reset_health_check_token
    put :clear_repository_check_states
  end

  ## EE-specific
  resource :license, only: [:show, :new, :create, :destroy] do
    get :download, on: :member
  end

  resources :geo_nodes, only: [:index, :create, :destroy] do
    member do
      post :repair
      post :backfill_repositories
    end
  end
  ## EE-specific

  resources :labels

  resources :runners, only: [:index, :show, :update, :destroy] do
    member do
      get :resume
      get :pause
    end
  end

  resources :builds, only: :index do
    collection do
      post :cancel_all
    end
  end

  root to: 'dashboard#index'
end
