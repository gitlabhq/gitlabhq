<<<<<<< HEAD
## EE-specific
get  'unsubscribes/:email', to: 'unsubscribes#show', as: :unsubscribe
post 'unsubscribes/:email', to: 'unsubscribes#create'
## EE-specific

=======
>>>>>>> upstream/master
# Allows individual providers to be directed to a chosen controller
# Call from inside devise_scope
def override_omniauth(provider, controller, path_prefix = '/users/auth')
  match "#{path_prefix}/#{provider}/callback",
    to: "#{controller}##{provider}",
    as: "#{provider}_omniauth_callback",
    via: [:get, :post]
end

# Use custom controller for LDAP omniauth callback
if Gitlab::Auth::LDAP::Config.enabled?
  devise_scope :user do
    Gitlab::Auth::LDAP::Config.available_servers.each do |server|
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
  get '/users/auth/:provider/omniauth_error' => 'omniauth_callbacks#omniauth_error', as: :omniauth_error
  get '/users/almost_there' => 'confirmations#almost_there'

  ## EE-specific
  get '/users/auth/kerberos_spnego/negotiate' => 'omniauth_kerberos_spnego#negotiate'
  ## EE-specific
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
    get :snippets
    get :exists
    get :pipelines_quota
    get '/', to: redirect('%{username}'), as: nil
  end

  # Compatibility with old routing
  # TODO (dzaporozhets): remove in 10.0
  get '/u/:username', to: redirect('%{username}')
  # TODO (dzaporozhets): remove in 9.0
  get '/u/:username/groups', to: redirect('users/%{username}/groups')
  get '/u/:username/projects', to: redirect('users/%{username}/projects')
  get '/u/:username/snippets', to: redirect('users/%{username}/snippets')
  get '/u/:username/contributed', to: redirect('users/%{username}/contributed')
end

constraints(::Constraints::UserUrlConstrainer.new) do
  # Get all keys of user
  get ':username.keys' => 'profiles/keys#get_keys', constraints: { username: Gitlab::PathRegex.root_namespace_route_regex }

  scope(path: ':username',
        as: :user,
        constraints: { username: Gitlab::PathRegex.root_namespace_route_regex },
        controller: :users) do
    get '/', action: :show
  end
end
