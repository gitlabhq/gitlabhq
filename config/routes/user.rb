require 'constraints/user_url_constrainer'

devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks,
                                  registrations: :registrations,
                                  passwords: :passwords,
                                  sessions: :sessions,
                                  confirmations: :confirmations }

devise_scope :user do
  get '/users/auth/:provider/omniauth_error' => 'omniauth_callbacks#omniauth_error', as: :omniauth_error
  get '/users/almost_there' => 'confirmations#almost_there'
end

constraints(UserUrlConstrainer.new) do
  scope(path: ':username',
        as: :user,
        constraints: { username: Gitlab::Regex.namespace_route_regex },
        controller: :users) do
    get '/', action: :show
  end
end

scope(constraints: { username: Gitlab::Regex.namespace_route_regex }) do
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
    get '/', to: redirect('/%{username}')
  end

  # Compatibility with old routing
  # TODO (dzaporozhets): remove in 10.0
  get '/u/:username', to: redirect('/%{username}')
  # TODO (dzaporozhets): remove in 9.0
  get '/u/:username/groups', to: redirect('/users/%{username}/groups')
  get '/u/:username/projects', to: redirect('/users/%{username}/projects')
  get '/u/:username/snippets', to: redirect('/users/%{username}/snippets')
  get '/u/:username/contributed', to: redirect('/users/%{username}/contributed')
end
