# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'product_analytics/collector_app'

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

  use_doorkeeper do
    controllers applications: 'oauth/applications',
                authorized_applications: 'oauth/authorized_applications',
                authorizations: 'oauth/authorizations',
                token_info: 'oauth/token_info',
                tokens: 'oauth/tokens'
  end

  # This prefixless path is required because Jira gets confused if we set it up with a path
  # More information: https://gitlab.com/gitlab-org/gitlab/issues/6752
  scope path: '/login/oauth', controller: 'oauth/jira/authorizations', as: :oauth_jira do
    get :authorize, action: :new
    get :callback
    post :access_token

    match '*all', via: [:get, :post], to: proc { [404, {}, ['']] }
  end

  draw :oauth

  use_doorkeeper_openid_connect
  # Add OPTIONS method for CORS preflight requests
  match '/oauth/userinfo' => 'doorkeeper/openid_connect/userinfo#show', via: :options
  match '/oauth/discovery/keys' => 'doorkeeper/openid_connect/discovery#keys', via: :options
  match '/.well-known/openid-configuration' => 'doorkeeper/openid_connect/discovery#provider', via: :options
  match '/.well-known/webfinger' => 'doorkeeper/openid_connect/discovery#webfinger', via: :options

  match '/oauth/token' => 'oauth/tokens#create', via: :options
  match '/oauth/revoke' => 'oauth/tokens#revoke', via: :options

  # Sign up
  scope path: '/users/sign_up', module: :registrations, as: :users_sign_up do
    resource :welcome, only: [:show, :update], controller: 'welcome' do
      Gitlab.ee do
        get :trial_getting_started, on: :collection
        get :trial_onboarding_board, on: :collection
        get :continuous_onboarding_getting_started, on: :collection
      end
    end

    resource :experience_level, only: [:show, :update]

    Gitlab.ee do
      resources :groups, only: [:new, :create]
      resources :projects, only: [:new, :create]
    end
  end

  # Search
  get 'search' => 'search#show', as: :search
  get 'search/autocomplete' => 'search#autocomplete', as: :search_autocomplete
  get 'search/count' => 'search#count', as: :search_count
  get 'search/opensearch' => 'search#opensearch', as: :search_opensearch

  # JSON Web Token
  get 'jwt/auth' => 'jwt#auth'

  # Health check
  get 'health_check(/:checks)' => 'health_check#index', as: :health_check

  # Terraform service discovery
  get '.well-known/terraform.json' => 'terraform/services#index', as: :terraform_services

  # Begin of the /-/ scope.
  # Use this scope for all new global routes.
  scope path: '-' do
    # Autocomplete
    get '/autocomplete/users' => 'autocomplete#users'
    get '/autocomplete/users/:id' => 'autocomplete#user'
    get '/autocomplete/projects' => 'autocomplete#projects'
    get '/autocomplete/award_emojis' => 'autocomplete#award_emojis'
    get '/autocomplete/merge_request_target_branches' => 'autocomplete#merge_request_target_branches'
    get '/autocomplete/deploy_keys_with_owners' => 'autocomplete#deploy_keys_with_owners'

    Gitlab.ee do
      get '/autocomplete/project_groups' => 'autocomplete#project_groups'
      get '/autocomplete/project_routes' => 'autocomplete#project_routes'
      get '/autocomplete/namespace_routes' => 'autocomplete#namespace_routes'
    end

    get '/whats_new' => 'whats_new#index'

    # '/-/health' implemented by BasicHealthCheck middleware
    get 'liveness' => 'health#liveness'
    get 'readiness' => 'health#readiness'
    controller :metrics do
      get 'metrics', action: :index
      get 'metrics/system', action: :system
    end
    mount Peek::Railtie => '/peek', as: 'peek_routes'

    get 'runner_setup/platforms' => 'runner_setup#platforms'

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

    scope :ide, as: :ide, format: false do
      get '/', to: 'ide#index'
      get '/project', to: 'ide#index'

      scope path: 'project/:project_id', as: :project, constraints: { project_id: Gitlab::PathRegex.full_namespace_route_regex } do
        %w[edit tree blob].each do |action|
          get "/#{action}", to: 'ide#index'
          get "/#{action}/*branch/-/*path", to: 'ide#index'
          get "/#{action}/*branch/-", to: 'ide#index'
          get "/#{action}/*branch", to: 'ide#index'
        end

        get '/merge_requests/:merge_request_id', to: 'ide#index', constraints: { merge_request_id: /\d+/ }
        get '/', to: 'ide#index'
      end
    end

    resource :projects

    draw :operations
    draw :jira_connect

    Gitlab.ee do
      draw :security
      draw :smartcard
      draw :username
      draw :trial
      draw :trial_registration
      draw :country
      draw :country_state
      draw :subscription

      scope '/push_from_secondary/:geo_node_id' do
        draw :git_http
      end

      # Used for survey responses
      resources :survey_responses, only: :index
    end

    Gitlab.jh do
      draw :province
    end

    if ENV['GITLAB_CHAOS_SECRET'] || Rails.env.development? || Rails.env.test?
      resource :chaos, only: [] do
        get :leakmem
        get :cpu_spin
        get :db_spin
        get :sleep
        get :kill
        get :quit
        post :gc
      end
    end

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

    # JWKS (JSON Web Key Set) endpoint
    # Used by third parties to verify CI_JOB_JWT
    get 'jwks' => 'jwks#index'

    draw :snippets
    draw :profile

    # Product analytics collector
    match '/collector/i', to: ProductAnalytics::CollectorApp.new, via: :all
  end
  # End of the /-/ scope.

  concern :clusterable do
    resources :clusters, only: [:index, :new, :show, :update, :destroy] do
      collection do
        post :create_user
        post :create_gcp
        post :create_aws
        post :authorize_aws_role
      end

      resource :integration, controller: 'clusters/integrations', only: [] do
        collection do
          post :create_or_update
        end
      end

      member do
        Gitlab.ee do
          get :metrics, format: :json
          get :environments, format: :json
        end

        scope :applications do
          post '/:application', to: 'clusters/applications#create', as: :install_applications
          patch '/:application', to: 'clusters/applications#update', as: :update_applications
          delete '/:application', to: 'clusters/applications#destroy', as: :uninstall_applications
        end

        get :metrics_dashboard
        get :'/prometheus/api/v1/*proxy_path', to: 'clusters#prometheus_proxy', as: :prometheus_api
        get :cluster_status, format: :json
        delete :clear_cache
      end
    end
  end

  resources :groups, only: [:index, :new, :create] do
    post :preview_markdown
  end

  draw :group

  resources :projects, only: [:index, :new, :create]

  get '/projects/:id' => 'projects#resolve'

  draw :git_http
  draw :api
  draw :customers_dot
  draw :sidekiq
  draw :help
  draw :google_api
  draw :import
  draw :uploads
  draw :explore
  draw :admin
  draw :dashboard
  draw :user
  draw :project
  draw :unmatched_project

  # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/210024
  scope as: 'deprecated' do
    # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/223719
    get '/snippets/:id/raw',
      to: 'snippets#raw',
      format: false,
      constraints: { id: /\d+/ }

    Gitlab::Routing.redirect_legacy_paths(self, :snippets)
  end

  Gitlab.ee do
    get '/sitemap' => 'sitemap#show', format: :xml
  end

  # Creates shorthand helper methods for project resources.
  # For example; for the `namespace_project_path` this also creates `project_path`.
  #
  # TODO: We don't need the `Gitlab::Routing` module at all as we can use
  # the `direct` DSL method of Rails to define url helpers. Move all the
  # custom url helpers to use the `direct` DSL method and remove the `Gitlab::Routing`.
  # For more information: https://gitlab.com/gitlab-org/gitlab/-/issues/299583
  Gitlab::Application.routes.set.filter_map { |route| route.name if route.name&.include?('namespace_project') }.each do |name|
    new_name = name.sub('namespace_project', 'project')

    direct(new_name) do |project, *args|
      # This is due to a bug I've found in Rails.
      # For more information: https://gitlab.com/gitlab-org/gitlab/-/issues/299591
      args.pop if args.last == {}

      send("#{name}_url", project&.namespace, project, *args)
    end
  end

  root to: "root#index"

  get '*unmatched_route', to: 'application#route_not_found'
end

Gitlab::Routing.add_helpers(TimeboxesRoutingHelper)
