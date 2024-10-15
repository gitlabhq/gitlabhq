# frozen_string_literal: true

# Alias import callbacks under the /users/auth endpoint so that
# the OAuth2 callback URL can be restricted under http://example.com/users/auth
# instead of http://example.com.
Devise.omniauth_providers.map(&:downcase).each do |provider|
  next if provider == 'ldapmain'

  get "/users/auth/-/import/#{provider}/callback", to: "import/#{provider}#callback", as: "users_import_#{provider}_callback"
end

namespace :import do
  resources :history, only: [:index], controller: :history

  namespace :url do
    post :validate
  end

  resource :github, only: [:create, :new], controller: :github do
    post :personal_access_token
    get :status
    get :details
    get :callback
    get :realtime_changes
    get :failures
    post :cancel
    post :cancel_all
    get :counts
  end

  resource :gitea, only: [:create, :new], controller: :gitea do
    post :personal_access_token
    get :status
    get :realtime_changes
  end

  resource :bitbucket, only: [:create], controller: :bitbucket do
    get :status
    get :callback
    get :realtime_changes
  end

  resource :bitbucket_server, only: [:create, :new], controller: :bitbucket_server do
    post :configure
    get :status
    get :callback
    get :realtime_changes
  end

  resource :fogbugz, only: [:create, :new], controller: :fogbugz do
    get :status
    post :callback
    get :realtime_changes

    get   :new_user_map,    path: :user_map
    post  :create_user_map, path: :user_map
  end

  resource :gitlab_project, only: [:create, :new] do
    post :create
    post :authorize
  end

  resource :gitlab_group, only: [:create] do
    post :authorize
  end

  resource :github_group, only: [] do
    get :status
  end

  resource :bulk_imports, only: [:create] do
    post :configure
    get :status
    get :realtime_changes
    get :history
  end

  resources :bulk_imports, only: [] do
    member do
      get :history
      get '/history/:entity_id/failures', action: :failures, as: :failures
    end
  end

  resource :manifest, only: [:create, :new], controller: :manifest do
    get :status
    get :realtime_changes
    post :upload
  end

  resources :source_users, param: :reassignment_token, only: [] do
    member do
      get :show
      post :accept
      post :decline
    end
  end
end
