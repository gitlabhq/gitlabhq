# frozen_string_literal: true

# Repository routes without /-/ scope.
# Issue https://gitlab.com/gitlab-org/gitlab/-/issues/28848.
# Do not add new routes here. Add new routes to repository.rb instead
# (see https://docs.gitlab.com/ee/development/routing.html#project-routes).

resource :repository, only: [:create]

# Don't use format parameter as file extension (old 3.0.x behavior)
# See http://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments
scope format: false do
  get '/refs/switch',
    to: redirect('%{namespace_id}/%{project_id}/-/refs/switch')

  get '/refs/:id/logs_tree',
    to: redirect('%{namespace_id}/%{project_id}/-/refs/%{id}/logs_tree'),
    constraints: { id: Gitlab::PathRegex.git_reference_regex }

  get '/refs/:id/logs_tree/*path',
    constraints: { id: /.*/, path: /[^\0]*/ },
    to: redirect { |params, _request|
      path = params[:path]
      path.gsub!('@', '-/')
      Addressable::URI.escape("#{params[:namespace_id]}/#{params[:project_id]}/-/refs/#{params[:id]}/logs_tree/#{path}")
    }

  scope constraints: { id: /[^\0]+/ } do
    # Deprecated. Keep for compatibility.
    # Issue https://gitlab.com/gitlab-org/gitlab/-/issues/118849
    get '/tree/*id', to: 'tree#show', as: :deprecated_tree
    get '/blob/*id', to: 'blob#show', as: :deprecated_blob
    get '/raw/*id', to: 'raw#show', as: :deprecated_raw
    get '/blame/*id', to: 'blame#show', as: :deprecated_blame

    # Redirect those explicitly since `redirect_legacy_paths` conflicts with project new/edit actions
    get '/new/*id', to: redirect('%{namespace_id}/%{project_id}/-/new/%{id}')
    get '/edit/*id', to: redirect('%{namespace_id}/%{project_id}/-/edit/%{id}')
  end
end
