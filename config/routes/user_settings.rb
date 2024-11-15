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
      put :rotate
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
