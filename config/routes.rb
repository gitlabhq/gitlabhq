# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

InitializerConnections.raise_if_new_database_connection do
  Rails.application.routes.draw do
    concern :access_requestable do
      get :request_access, on: :collection
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

    draw :development

    use_doorkeeper do
      controllers applications: 'oauth/applications',
        authorized_applications: 'oauth/authorized_applications',
        authorizations: 'oauth/authorizations',
        token_info: 'oauth/token_info',
        tokens: 'oauth/tokens'
    end
    put '/oauth/applications/:id/renew(.:format)' => 'oauth/applications#renew', as: :renew_oauth_application

    draw :oauth

    use_doorkeeper_openid_connect do
      controllers discovery: 'jwks'
    end

    use_doorkeeper_device_authorization_grant do
      controller device_authorizations: 'oauth/device_authorizations'
    end

    # Add OPTIONS method for CORS preflight requests
    match '/oauth/userinfo' => 'doorkeeper/openid_connect/userinfo#show', via: :options
    match '/oauth/discovery/keys' => 'jwks#keys', via: :options
    match '/.well-known/openid-configuration' => 'jwks#provider', via: :options
    match '/.well-known/webfinger' => 'jwks#webfinger', via: :options

    match '/oauth/token' => 'oauth/tokens#create', via: :options
    match '/oauth/revoke' => 'oauth/tokens#revoke', via: :options

    match '/-/jira_connect/oauth_application_id' => 'jira_connect/oauth_application_ids#show', via: :options
    match '/-/jira_connect/subscriptions(.:format)' => 'jira_connect/subscriptions#index', via: :options
    match '/-/jira_connect/subscriptions/:id' => 'jira_connect/subscriptions#delete', via: :options

    # Sign up
    scope path: '/users/sign_up', module: :registrations, as: :users_sign_up do
      Gitlab.ee do
        resource :welcome, only: [:show, :update], controller: 'welcome'
        resource :company, only: [:new, :create], controller: 'company'
        resources :groups, only: [:new, :create]
      end
    end

    # Search
    get 'search' => 'search#show', as: :search
    get 'search/autocomplete' => 'search#autocomplete', as: :search_autocomplete
    get 'search/settings' => 'search#settings'
    get 'search/count' => 'search#count', as: :search_count
    get 'search/opensearch' => 'search#opensearch', as: :search_opensearch

    Gitlab.ee do
      get 'search/aggregations' => 'search#aggregations', as: :search_aggregations
    end

    # JSON Web Token
    get 'jwt/auth' => 'jwt#auth'
    post 'jwt/auth', to: proc { [404, {}, ['']] }

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
      get '/autocomplete/merge_request_source_branches' => 'autocomplete#merge_request_source_branches'
      get '/autocomplete/deploy_keys_with_owners' => 'autocomplete#deploy_keys_with_owners'

      Gitlab.ee do
        get '/autocomplete/project_groups' => 'autocomplete#project_groups'
        get '/autocomplete/project_routes' => 'autocomplete#project_routes'
        get '/autocomplete/namespace_routes' => 'autocomplete#namespace_routes'
        get '/autocomplete/group_subgroups' => 'autocomplete#group_subgroups'
      end

      # sandbox
      get '/sandbox/mermaid' => 'sandbox#mermaid'
      get '/sandbox/swagger' => 'sandbox#swagger'

      get '/:model/:model_id/uploads/:secret/:filename',
        to: 'banzai/uploads#show',
        constraints: {
          model: /project|group/,
          filename: %r{[^/]+}
        },
        as: 'banzai_upload'

      get '/whats_new' => 'whats_new#index'

      get 'offline' => "pwa#offline"
      get 'manifest' => "pwa#manifest", constraints: ->(req) { req.format == :json }

      scope module: 'clusters' do
        scope module: 'agents' do
          get '/kubernetes', to: 'dashboard#index', as: 'kubernetes_dashboard_index'
          get '/kubernetes/:agent_id(/*vueroute)', to: 'dashboard#show', as: 'kubernetes_dashboard'
        end
      end

      # HTTP Router
      # Creating a black hole for /-/http_router/version since it is taken by the
      # cloudflare worker, see: https://gitlab.com/gitlab-org/cells/http-router/-/issues/47
      match '/http_router/version', to: proc { [204, {}, ['']] }, via: :all

      # '/-/health' implemented by BasicHealthCheck middleware
      get 'liveness' => 'health#liveness'
      get 'readiness' => 'health#readiness'
      controller :metrics do
        get 'metrics', action: :index
        get 'metrics/system', action: :system
      end
      mount Peek::Railtie => '/peek', as: 'peek_routes'

      get 'runner_setup/platforms' => 'runner_setup#platforms'

      get 'acme-challenge/' => 'acme_challenges#show'

      scope :ide, as: :ide, format: false do
        get '/', to: 'ide#index'
        get '/project', to: 'ide#index'
        # note: This path has a hardcoded reference in the FE `app/assets/javascripts/ide/constants.js`
        get '/oauth_redirect', to: 'ide#oauth_redirect'

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

        post '/reset_oauth_application_settings' => 'admin/applications#reset_web_ide_oauth_application_settings'
      end

      draw :operations
      draw :jira_connect
      draw :organizations

      Gitlab.ee do
        draw :remote_development
        draw :security
        draw :smartcard
        draw :trial_registration
        draw :country
        draw :country_state
        draw :gitlab_subscriptions
        draw :phone_verification
        draw :arkose

        scope '/push_from_secondary/:geo_node_id' do
          draw :git_http
        end
      end

      Gitlab.jh do
        draw :global_jh
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
          match :unsubscribe, via: [:get, :post]
        end
      end

      # Spam reports
      resources :abuse_reports, only: [:create] do
        collection do
          post :add_category
        end
      end

      # JWKS (JSON Web Key Set) endpoint
      # Used by third parties to verify CI_JOB_JWT
      get 'jwks' => 'jwks#index'

      draw :snippets
      draw :profile
      draw :user_settings

      post '/mailgun/webhooks' => 'mailgun/webhooks#process_webhook'

      # Deprecated route for permanent failures
      # https://gitlab.com/gitlab-org/gitlab/-/issues/362606
      post '/members/mailgun/permanent_failures' => 'mailgun/webhooks#process_webhook'

      get '/timelogs' => 'time_tracking/timelogs#index'

      post '/track_namespace_visits' => 'users/namespace_visits#create'

      get '/external_redirect' => 'external_redirect/external_redirect#index'
    end
    # End of the /-/ scope.

    concern :clusterable do
      resources :clusters, only: [:index, :show, :update, :destroy] do
        collection do
          get  :connect
          get  :new_cluster_docs
          post :create_user
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

          get :metrics_dashboard
          get :cluster_status, format: :json
          delete :clear_cache
        end
      end
    end

    resources :groups, only: [:index, :new, :create]

    get '/-/g/:id' => 'groups/redirect#redirect_from_id'

    draw :group

    resources :projects, only: [:index, :new, :create]

    get '/projects/:id' => 'projects/redirect#redirect_from_id'
    get '/-/p/:id' => 'projects/redirect#redirect_from_id'

    draw :git_http
    draw :api
    draw :activity_pub
    draw :customers_dot
    draw :device_auth
    draw :sidekiq
    draw :help
    draw :google_api
    draw :import
    draw :uploads
    draw :explore
    draw :admin
    draw :dashboard
    draw :identity_verification
    draw :user
    draw :project
    draw :unmatched_project
    draw :well_known

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
    # For more information: https://gitlab.com/groups/gitlab-org/-/epics/9866
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

    get '*unmatched_route', to: 'application#route_not_found', format: false

    # Load all custom URLs definitions via `direct' after the last route
    # definition.
    draw :directs
  end
end
