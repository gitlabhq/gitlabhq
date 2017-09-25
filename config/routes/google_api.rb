namespace :google_api do
  resource :authorizations, only: [], controller: :authorizations do
    match :callback, via: [:get, :post]
  end
end
