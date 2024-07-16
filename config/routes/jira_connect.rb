# frozen_string_literal: true

namespace :jira_connect do
  # This is so we can have a named route helper for the base URL
  root to: proc { [404, {}, ['']] }, as: 'base'

  get 'app_descriptor' => 'app_descriptor#show'

  namespace :events do
    post 'installed'
    post 'uninstalled'
  end

  resources :subscriptions, only: [:index, :create, :destroy]
  resources :branches, only: [:new] do
    collection do
      get :route
    end
  end
  resources :public_keys, only: :show

  resources :workspaces, only: [] do
    collection do
      get :search
    end
  end
  resources :repositories, only: [] do
    collection do
      get :search
      post :associate
    end
  end

  resources :installations, only: [:index] do
    collection do
      put :update
    end
  end

  resources :oauth_callbacks, only: [:index]
  resource :oauth_application_id, only: [:show]
end
