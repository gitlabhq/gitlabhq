# frozen_string_literal: true

namespace :explore do
  resources :projects, only: [:index] do
    collection do
      get :trending
      get :starred
      get :topics
      get 'topics/:topic_name', action: :topic, as: :topic, constraints: { format: /(html|atom)/, topic_name: /.+?/ }
    end
  end

  resources :groups, only: [:index]
  scope :catalog do
    get '/' => 'catalog#index', as: :catalog_index
    get '/*full_path' => 'catalog#show', as: :catalog, constraints: { full_path: /.*/ }
  end
  get '/ai-catalog/(*vueroute)' => 'ai_catalog#index', as: :ai_catalog, format: false
  resources :snippets, only: [:index]
  root to: 'projects#index'
end

# Compatibility with old routing
get 'public' => 'explore/projects#index'
get 'public/projects' => 'explore/projects#index'
