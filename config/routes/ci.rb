namespace :ci do
  # CI API
  Ci::API::API.logger Rails.logger
  mount Ci::API::API => '/api'

  resource :lint, only: [:show, :create]

  resources :projects, only: [:index, :show] do
    member do
      get :status, to: 'projects#badge'
    end
  end

  root to: 'projects#index'
end
