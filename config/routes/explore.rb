# frozen_string_literal: true

namespace :explore do
  resources :projects, only: [:index] do
    collection do
      get :trending
      get :starred
    end
  end

  resources :groups, only: [:index]
  resources :snippets, only: [:index]
  root to: 'projects#index'
end

# Compatibility with old routing
get 'public' => 'explore/projects#index'
get 'public/projects' => 'explore/projects#index'
