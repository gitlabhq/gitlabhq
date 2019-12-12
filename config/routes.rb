require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  concern :access_requestable do
    post :request_access, on: :collection
    post :approve_access_request, on: :member
  end

  concern :awardable do
    post :toggle_award_emoji, on: :member
  end

  favicon_redirect = redirect do |_params, _request|
    ActionController::Base.helpers.asset_url(Gitlab::Favicon.main)
  end
  get 'favicon.png', to: favicon_redirect
  get 'favicon.ico', to: favicon_redirect

  draw :sherlock
  draw :development
  draw :ci

  use_doorkeeper do
    controllers applications: 'oauth/applications',
                authorized_applications: 'oauth/authorized_applications',
                authorizations: 'oauth/authorizations'
  end

  # This prefixless path is required because Jira gets confused if we set it up with a path
  # More information: https://gitlab.com/gitlab-org/gitlab/issues/6752
  scope path: '/login/oauth', controller: 'oauth/jira/authorizations', as: :oauth_jira do
    Gitlab.ee do
      get :authorize, action: :new
      get :callback
      post :access_token
    end

    # This helps minimize merge conflicts with CE for this scope block
    match '*all', via: [:get, :post], to: proc { [404, {}, ['']] }
  end

  draw :oauth

  use_doorkeeper_openid_connect

  # Autocomplete
  get '/autocomplete/users' => 'autocomplete#users'
  get '/autocomplete/users/:id' => 'autocomplete#user'
  get '/autocomplete/projects' => 'autocomplete#projects'
  get '/autocomplete/award_emojis' => 'autocomplete#award_emojis'
  get '/autocomplete/merge_request_target_branches' => 'autocomplete#merge_request_target_branches'

  Gitlab.ee do
    get '/autocomplete/project_groups' => 'autocomplete#project_groups'
  end

  # Sign up
  get 'users/sign_up/welcome' => 'registrations#welcome'
  patch 'users/sign_up/update_registration' => 'registrations#update_registration'

  # Search
  get 'search' => 'search#show'
  get 'search/autocomplete' => 'search#autocomplete', as: :search_autocomplete
  get 'search/count' => 'search#count', as: :search_count

  # JSON Web Token
  get 'jwt/auth' => 'jwt#auth'

  # Health check
  get 'health_check(/:checks)' => 'health_check#index', as: :health_check

  scope path: '-' do
    # '/-/health' implemented by BasicHealthCheck middleware
    get 'liveness' => 'health#liveness'
    get 'readiness' => 'health#readiness'
    resources :metrics, only: [:index]
    mount Peek::Railtie => '/peek', as: 'peek_routes'

    # Boards resources shared between group and projects
    resources :boards, only: [] do
      resources :lists, module: :boards, only: [:index, :create, :update, :destroy] do
        collection do
          post :generate
        end

        resources :issues, only: [:index, :create, :update]
      end

      resources :issues, module: :boards, only: [:index, :update] do
        collection do
          put :bulk_move, format: :json
        end
      end

      Gitlab.ee do
        resources :users, module: :boards, only: [:index]
        resources :milestones, module: :boards, only: [:index]
      end
    end

    get 'acme-challenge/' => 'acme_challenges#show'

    # UserCallouts
    resources :user_callouts, only: [:create]

    get 'ide' => 'ide#index'
    get 'ide/*vueroute' => 'ide#index', format: false

    draw :operations
    draw :instance_statistics

    Gitlab.ee do
      draw :security
      draw :smartcard
      draw :jira_connect
      draw :username
      draw :trial
      draw :trial_registration
      draw :country
      draw :country_state
    end

    Gitlab.ee do
      constraints(-> (*) { Gitlab::Analytics.any_features_enabled? }) do
        draw :analytics
      end
    end

    if ENV['GITLAB_CHAOS_SECRET'] || Rails.env.development? || Rails.env.test?
      resource :chaos, only: [] do
        get :leakmem
        get :cpu_spin
        get :db_spin
        get :sleep
        get :kill
      end
    end
  end

  concern :clusterable do
    resources :clusters, only: [:index, :new, :show, :update, :destroy] do
      collection do
        post :create_user
        post :create_gcp
        post :create_aws
        post :authorize_aws_role
      end

      member do
        Gitlab.ee do
          get :metrics, format: :json
          get :metrics_dashboard
          get :'/prometheus/api/v1/*proxy_path', to: 'clusters#prometheus_proxy', as: :prometheus_api
          get :environments, format: :json
        end

        scope :applications do
          post '/:application', to: 'clusters/applications#create', as: :install_applications
          patch '/:application', to: 'clusters/applications#update', as: :update_applications
          delete '/:application', to: 'clusters/applications#destroy', as: :uninstall_applications
        end

        get :cluster_status, format: :json
        delete :clear_cache
      end
    end
  end

  draw :api
  draw :sidekiq
  draw :help
  draw :snippets

  # Invites
  resources :invites, only: [:show], constraints: { id: /[A-Za-z0-9_-]+/ } do
    member do
      post :accept
      match :decline, via: [:get, :post]
    end
  end

  resources :sent_notifications, only: [], constraints: { id: /\h{32}/ } do
    member do
      get :unsubscribe
    end
  end

  # Spam reports
  resources :abuse_reports, only: [:new, :create]

  # Notification settings
  resources :notification_settings, only: [:create, :update]

  draw :google_api
  draw :import
  draw :uploads
  draw :explore
  draw :admin
  draw :profile
  draw :dashboard
  draw :group
  draw :user
  draw :project

  root to: "root#index"

  get '*unmatched_route', to: 'application#route_not_found'
end
