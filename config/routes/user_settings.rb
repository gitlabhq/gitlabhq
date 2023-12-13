# frozen_string_literal: true

namespace :user_settings do
  scope module: 'user_settings' do
    get :authentication_log
    get :applications, to: '/oauth/applications#index'
  end
  resources :active_sessions, only: [:index, :destroy]
end

# Redirect routes till GitLab 17.0 release

resource :profile, only: [] do
  resources :active_sessions, only: [:destroy], controller: 'user_settings/active_sessions'
  member do
    get :active_sessions, to: redirect('-/user_settings/active_sessions')
  end
end
