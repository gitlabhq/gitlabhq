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
    Gitlab::Auth::Ldap::Config.available_servers.each do |server|
      override_omniauth(server['provider_name'], 'ldap/omniauth_callbacks')
    end
  end
end

devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks,
                                  registrations: :registrations,
                                  passwords: :passwords,
                                  sessions: :sessions,
                                  confirmations: :confirmations }

devise_scope :user do
  get '/users/almost_there' => 'confirmations#almost_there'
end

scope '-/users', module: :users do
  resources :terms, only: [:index] do
    post :accept, on: :member
    post :decline, on: :member
  end
end

scope(constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }) do
  scope(path: 'users/:username',
        as: :user,
        controller: :users) do
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
  get ':username.gpg' => 'users#gpg_keys', constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }

  scope(path: ':username',
        as: :user,
        constraints: { username: Gitlab::PathRegex.root_namespace_route_regex },
        controller: :users) do
    get '/', action: :show
  end
end
