require 'constraints/user_url_constrainer'

<<<<<<< HEAD
get '/u/:username', to: redirect('/%{username}'),
                    constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }

## EE-specific
get  'unsubscribes/:email', to: 'unsubscribes#show', as: :unsubscribe
post 'unsubscribes/:email', to: 'unsubscribes#create'
## EE-specific

=======
>>>>>>> ce/master
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

constraints(UserUrlConstrainer.new) do
  scope(path: ':username',
        as: :user,
        constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ },
        controller: :users) do
    get '/', action: :show
  end
end

scope(path: 'users/:username',
      as: :user,
      constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ },
      controller: :users) do
  get :calendar
  get :calendar_activities
  get :groups
  get :projects
  get :contributed, as: :contributed_projects
  get :snippets
  get :exists
  get '/', to: redirect('/%{username}')
end

# Compatibility with old routing
# TODO (dzaporozhets): remove in 10.0
get '/u/:username', to: redirect('/%{username}'), constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }
# TODO (dzaporozhets): remove in 9.0
get '/u/:username/groups', to: redirect('/users/%{username}/groups'), constraints: { username: /[a-zA-Z.0-9_\-]+/ }
get '/u/:username/projects', to: redirect('/users/%{username}/projects'), constraints: { username: /[a-zA-Z.0-9_\-]+/ }
get '/u/:username/snippets', to: redirect('/users/%{username}/snippets'), constraints: { username: /[a-zA-Z.0-9_\-]+/ }
get '/u/:username/contributed', to: redirect('/users/%{username}/contributed'), constraints: { username: /[a-zA-Z.0-9_\-]+/ }
