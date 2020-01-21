# frozen_string_literal: true

# All routing related to repository browsing
# that is already under /-/ scope only

# Don't use format parameter as file extension (old 3.0.x behavior)
# See http://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments
scope format: false do
  scope constraints: { id: Gitlab::PathRegex.git_reference_regex } do
    resources :network, only: [:show]

    resources :graphs, only: [:show] do
      member do
        get :charts
        get :commits
        get :ci
        get :languages
      end
    end

    get '/branches/:state', to: 'branches#index', as: :branches_filtered, constraints: { state: /active|stale|all/ }
    resources :branches, only: [:index, :new, :create, :destroy] do
      get :diverging_commit_counts, on: :collection
    end

    delete :merged_branches, controller: 'branches', action: :destroy_all_merged
    resources :tags, only: [:index, :show, :new, :create, :destroy] do
      resource :release, controller: 'tags/releases', only: [:edit, :update]
    end

    resources :protected_branches, only: [:index, :show, :create, :update, :destroy, :patch], constraints: { id: Gitlab::PathRegex.git_reference_regex }
    resources :protected_tags, only: [:index, :show, :create, :update, :destroy]
  end
end
