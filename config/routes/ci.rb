namespace :ci do
  resource :lint, only: :show

  root to: redirect('')
end
