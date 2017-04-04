namespace :ci do
  # CI API
  Ci::API::API.logger Rails.logger
  mount Ci::API::API => '/api'

  resource :lint, only: [:show, :create]

  root to: redirect('/')
end
