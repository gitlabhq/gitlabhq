# frozen_string_literal: true

namespace :user_settings do
  scope module: 'user_settings' do
    get :authentication_log
    get :applications, to: '/oauth/applications#index'
  end
  resources :active_sessions, only: [:index, :destroy]
  resource :profile, only: [:show, :update]
  resource :identities, only: [:new, :create]
  resource :password, only: [:new, :create, :edit, :update] do
    member do
      put :reset
    end
  end
  resources :personal_access_tokens, only: [:index, :create] do
    member do
      put :revoke
    end
  end
  resources :gpg_keys, only: [:index, :create, :destroy] do
    member do
      put :revoke
    end
  end
  resources :ssh_keys, only: [:index, :show, :create, :destroy] do
    member do
      delete :revoke
    end
  end
end

# Redirect routes till GitLab 17.0 release

resource :profile, only: [] do
  resources :active_sessions, only: [:destroy], controller: 'user_settings/active_sessions'
  resources :personal_access_tokens, controller: 'user_settings/personal_access_tokens', only: [] do
    member do
      put :revoke
    end
  end
  member do
    get :show, to: redirect(path: '-/user_settings/profile')
    put :update, controller: 'user_settings/profiles'
    patch :update, controller: 'user_settings/profiles'

    get :active_sessions, to: redirect(path: '-/user_settings/active_sessions')
    get :personal_access_tokens, to: redirect(path: '-/user_settings/personal_access_tokens')
  end
  get 'password/new', to: redirect(path: '-/user_settings/password/new')
  get "password/edit", to: redirect(path: '-/user_settings/password/edit')

  get 'gpg_keys', to: redirect(path: '-/user_settings/gpg_keys#index')
  post 'gpg_keys', to: redirect(path: '-/user_settings/gpg_keys#create')
  get 'gpg_keys/:id', to: redirect(path: '-/user_settings/gpg_keys#show')
  delete 'gpg_keys/:id', to: redirect(path: '-/user_settings/gpg_keys#destroy')

  get 'keys', to: redirect(path: '-/user_settings/ssh_keys#index')
  post 'keys', to: redirect(path: '-/user_settings/ssh_keys#create')
  get 'keys/:id', to: redirect(path: '-/user_settings/ssh_keys#show')
  delete 'keys/:id', to: redirect(path: '-/user_settings/ssh_keys#destroy')
end
