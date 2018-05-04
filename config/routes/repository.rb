# All routing related to repository browsing

resource :repository, only: [:create] do
  member do
    # deprecated since GitLab 9.5
    get 'archive', constraints: { format: Gitlab::PathRegex.archive_formats_regex }, as: 'archive_alternative', defaults: { append_sha: true }

    # deprecated since GitLab 10.7
    get ':id/archive', constraints: { format: Gitlab::PathRegex.archive_formats_regex, id: /.+/ }, action: 'archive', as: 'archive_deprecated', defaults: { append_sha: true }
  end
end

# Don't use format parameter as file extension (old 3.0.x behavior)
# See http://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments
scope format: false do
  get '/compare/:from...:to', to: 'compare#show', as: 'compare', constraints: { from: /.+/, to: /.+/ }

  resources :compare, only: [:index, :create] do
    collection do
      get :diff_for_path
    end
  end

  resources :refs, only: [] do
    collection do
      get 'switch'
    end

    member do
      # tree viewer logs
      get 'logs_tree', constraints: { id: Gitlab::PathRegex.git_reference_regex }
      # Directories with leading dots erroneously get rejected if git
      # ref regex used in constraints. Regex verification now done in controller.
      get 'logs_tree/*path', action: :logs_tree, as: :logs_file, format: false, constraints: {
        id: /.*/,
        path: /.*/
      }
    end
  end

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
    resources :branches, only: [:index, :new, :create, :destroy]
    delete :merged_branches, controller: 'branches', action: :destroy_all_merged
    resources :tags, only: [:index, :show, :new, :create, :destroy] do
      resource :release, only: [:edit, :update]
    end

    resources :protected_branches, only: [:index, :show, :create, :update, :destroy]
    resources :protected_tags, only: [:index, :show, :create, :update, :destroy]
  end

  scope constraints: { id: /.+/ }  do
    scope controller: :blob do
      get '/new/*id', action: :new, as: :new_blob
      post '/create/*id', action: :create, as: :create_blob
      get '/edit/*id', action: :edit, as: :edit_blob
      put '/update/*id', action: :update, as: :update_blob
      post '/preview/*id', action: :preview, as: :preview_blob

      scope path: '/blob/*id', as: :blob do
        get :diff
        get '/', action: :show
        delete '/', action: :destroy
        post '/', action: :create
        put '/', action: :update
      end
    end

    get '/tree/*id', to: 'tree#show', as: :tree
    get '/raw/*id', to: 'raw#show', as: :raw
    get '/blame/*id', to: 'blame#show', as: :blame

    get '/commits/*id/signatures', to: 'commits#signatures', as: :signatures
    get '/commits/*id', to: 'commits#show', as: :commits

    post '/create_dir/*id', to: 'tree#create_dir', as: :create_dir

    scope controller: :find_file do
      get '/find_file/*id', action: :show, as: :find_file

      get '/files/*id', action: :list, as: :files
    end
  end
end
