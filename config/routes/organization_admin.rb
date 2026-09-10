# frozen_string_literal: true

namespace :admin do
  root to: 'organizations/dashboard#index'

  scope module: :organizations do
    resources :users, only: [:index, :show, :edit, :update], constraints: { id: %r{[a-zA-Z./0-9_-]+} }
    resources :cohorts, only: [:index]
  end
end
