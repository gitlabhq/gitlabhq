namespace :ci do
  resource :lint, only: [:show, :create]

  root to: redirect('')
end
