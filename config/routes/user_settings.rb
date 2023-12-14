# frozen_string_literal: true

namespace :user_settings do
  scope module: 'user_settings' do
    get :authentication_log
    get :applications, to: '/oauth/applications#index'
  end
  resources :active_sessions, only: [:index, :destroy]
  resources :personal_access_tokens, only: [:index, :create] do
    member do
      put :revoke
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
    get :active_sessions, to: redirect(path: '-/user_settings/active_sessions')
    get :personal_access_tokens, to: redirect(path: '-/user_settings/personal_access_tokens')
  end
end
