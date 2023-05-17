# frozen_string_literal: true

# Repository routes without /-/ scope.
# Issue https://gitlab.com/gitlab-org/gitlab/-/issues/28848.
# Do not add new routes here. Add new routes to repository.rb instead
# (see https://docs.gitlab.com/ee/development/routing.html#project-routes).

resource :repository, only: [:create]

# Don't use format parameter as file extension (old 3.0.x behavior)
# See http://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments
scope format: false do
  scope constraints: { id: /[^\0]+/ } do
    # Deprecated. Keep for compatibility.
    # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/118849
    get '/tree/*id', to: 'tree#show', as: :deprecated_tree
    get '/blob/*id', to: 'blob#show', as: :deprecated_blob
    get '/raw/*id', to: 'raw#show', as: :deprecated_raw
    get '/blame/*id', to: 'blame#show', as: :deprecated_blame
  end
end
