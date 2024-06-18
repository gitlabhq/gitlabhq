# frozen_string_literal: true

get  'unsubscribes/:email', to: 'users/unsubscribes#show', as: :unsubscribe
post 'unsubscribes/:email', to: 'users/unsubscribes#create'

# Allows individual providers to be directed to a chosen controller
# Call from inside devise_scope
def override_omniauth(provider, controller, path_prefix = '/users/auth')
  match "#{path_prefix}/#{provider}/callback",
    to: "#{controller}##{provider}",
    as: "#{provider}_omniauth_callback",
    via: [:get, :post]
end

# Use custom controller for LDAP omniauth callback
if Gitlab::Auth::Ldap::Config.sign_in_enabled?
  devise_scope :user do
    Gitlab::Auth::Ldap::Config.servers.each do |server|
      override_omniauth(server['provider_name'], 'ldap/omniauth_callbacks')
    end
  end
end

devise_controllers = { omniauth_callbacks: :omniauth_callbacks,
                       registrations: :registrations,
                       passwords: :passwords,
                       sessions: :sessions,
                       confirmations: :confirmations }

if ::Gitlab.ee? && ::Gitlab::Geo.secondary?(infer_without_database: true)
  devise_for :users, controllers: devise_controllers, path_names: { sign_in: 'auth/geo/sign_in',
                                                                    sign_out: 'auth/geo/sign_out' }
  # When using Geo, the other type of routes should be present as well, as browsers
  # cache 302 redirects locally, and events like primary going offline or a failover
  # can result in browsers requesting the other paths because of it.
  as :user do
    get '/users/sign_in', to: 'sessions#new'
    post '/users/sign_in', to: 'sessions#create'
    post '/users/sign_out', to: 'sessions#destroy'
  end
else
  devise_for :users, controllers: devise_controllers

  # We avoid drawing Geo routes for FOSS, but keep them in for EE
  Gitlab.ee do
    as :user do
      get '/users/auth/geo/sign_in', to: 'sessions#new'
      post '/users/auth/geo/sign_in', to: 'sessions#create'
      post '/users/auth/geo/sign_out', to: 'sessions#destroy'
    end
  end
end

devise_scope :user do
  get '/users/almost_there' => 'confirmations#almost_there'
  post '/users/resend_verification_code', to: 'sessions#resend_verification_code'
  get '/users/successful_verification', to: 'sessions#successful_verification'
  patch '/users/update_email', to: 'sessions#update_email'

  # Redirect on GitHub authorization request errors. E.g. it could happen when user:
  # 1. cancel authorization the GitLab OAuth app via GitHub to import GitHub repos
  #   (they'll be redirected to /projects/new#import_project)
  # 2. cancel signing in to GitLab using GitHub account
  #   (they'll be redirected to /users/sign_in)
  # In these cases, GitHub redirects user to the GitLab OAuth app's
  # registered callback URL - /users/auth, which is the url to the auth user's profile page
  get '/users/auth',
    constraints: ->(req) {
      req.params[:error].present? && req.params[:state].present?
    },
    to: redirect { |_params, req|
      redirect_path = req.session.delete(:auth_on_failure_path)
      redirect_path || Rails.application.routes.url_helpers.new_user_session_path
    }
end

scope '-/users', module: :users do
  resources :terms, only: [:index] do
    post :accept, on: :member
    post :decline, on: :member
  end

  resources :callouts, only: [:create]
  resources :group_callouts, only: [:create]
  resources :project_callouts, only: [:create]
  resources :broadcast_message_dismissals, only: [:create]

  resource :pins, only: [:update]
end

scope(constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }) do
  scope(path: 'users/:username', as: :user, controller: :users) do
    get :calendar
    get :calendar_activities
    get :groups
    get :projects
    get :contributed, as: :contributed_projects
    get :starred, as: :starred_projects
    get :snippets
    get :followers
    get :following
    get :exists
    get :activity
    post :follow
    post :unfollow
    get '/', to: redirect('%{username}'), as: nil
  end
end

constraints(::Constraints::UserUrlConstrainer.new) do
  # Get all SSH keys of user
  get ':username.keys' => 'users#ssh_keys', constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }

  # Get all GPG keys of user
  get ':username.gpg' => 'users#gpg_keys', as: 'user_gpg_keys', constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }

  scope(
    path: ':username',
    as: :user,
    constraints: { username: Gitlab::PathRegex.root_namespace_route_regex },
    controller: :users
  ) do
    get '/', action: :show
  end
end
