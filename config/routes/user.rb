require 'constraints/user_url_constrainer'

get '/u/:username', to: redirect('/%{username}'),
                    constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ }

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
        constraints: { username: /[a-zA-Z.0-9_\-]+(?<!\.atom)/ },
        controller: :users) do
    get '/', action: :show
  end
end

scope(path: 'u/:username',
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
