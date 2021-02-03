# frozen_string_literal: true

scope '-' do
  namespace :google_api do
    resource :auth, only: [], controller: :authorizations do
      match :callback, via: [:get, :post]
    end
  end
end
