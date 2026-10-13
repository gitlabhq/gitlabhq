# frozen_string_literal: true

namespace :admin do
  root to: 'organizations/dashboard#index'

  scope module: :organizations do
    resources :users, only: [:index, :show, :edit, :update], constraints: { id: %r{[a-zA-Z./0-9_-]+} } do
      collection do
        get :invite_search, format: :json
      end
    end
    resources :cohorts, only: [:index]

    resource :settings, only: [] do
      get :general

      resources :integrations, only: [:index, :edit, :update] do
        member do
          get :overrides
          put :test
          post :reset
        end
      end
    end
  end
end
