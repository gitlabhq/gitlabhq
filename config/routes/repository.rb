# All routing related to repositoty browsing

resource :repository, only: [:create] do
  member do
    get 'archive', constraints: { format: Gitlab::Regex.archive_formats_regex }
  end
end

resources :refs, only: [] do
  collection do
    get 'switch'
  end

  member do
    # tree viewer logs
    get 'logs_tree', constraints: { id: Gitlab::Regex.git_reference_regex }
    # Directories with leading dots erroneously get rejected if git
    # ref regex used in constraints. Regex verification now done in controller.
    get 'logs_tree/*path' => 'refs#logs_tree', as: :logs_file, constraints: {
      id: /.*/,
      path: /.*/
    }
  end
end

get '/new/*id', to: 'blob#new', constraints: { id: /.+/ }, as: 'new_blob'
post '/create/*id', to: 'blob#create', constraints: { id: /.+/ }, as: 'create_blob'
get '/edit/*id', to: 'blob#edit', constraints: { id: /.+/ }, as: 'edit_blob'
put '/update/*id', to: 'blob#update', constraints: { id: /.+/ }, as: 'update_blob'
post '/preview/*id', to: 'blob#preview', constraints: { id: /.+/ }, as: 'preview_blob'

scope do
  get(
    '/blob/*id/diff',
    to: 'blob#diff',
    constraints: { id: /.+/, format: false },
    as: :blob_diff
  )
  get(
    '/blob/*id',
    to: 'blob#show',
    constraints: { id: /.+/, format: false },
    as: :blob
  )
  delete(
    '/blob/*id',
    to: 'blob#destroy',
    constraints: { id: /.+/, format: false }
  )
  put(
    '/blob/*id',
    to: 'blob#update',
    constraints: { id: /.+/, format: false }
  )
  post(
    '/blob/*id',
    to: 'blob#create',
    constraints: { id: /.+/, format: false }
  )

  get(
    '/raw/*id',
    to: 'raw#show',
    constraints: { id: /.+/, format: /(html|js)/ },
    as: :raw
  )

  get(
    '/tree/*id',
    to: 'tree#show',
    constraints: { id: /.+/, format: /(html|js)/ },
    as: :tree
  )

  get(
    '/find_file/*id',
    to: 'find_file#show',
    constraints: { id: /.+/, format: /html/ },
    as: :find_file
  )

  get(
    '/files/*id',
    to: 'find_file#list',
    constraints: { id: /(?:[^.]|\.(?!json$))+/, format: /json/ },
    as: :files
  )

  post(
    '/create_dir/*id',
      to: 'tree#create_dir',
      constraints: { id: /.+/ },
      as: 'create_dir'
  )

  get(
    '/blame/*id',
    to: 'blame#show',
    constraints: { id: /.+/, format: /(html|js)/ },
    as: :blame
  )

  # File/dir history
  get(
    '/commits/*id',
    to: 'commits#show',
    constraints: { id: /.+/, format: false },
    as: :commits
  )
end
