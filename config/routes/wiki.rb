WIKI_SLUG_ID = { id: /\S+/ } unless defined? WIKI_SLUG_ID

scope do
  # Order matters to give priority to these matches
  get '/wikis/git_access', to: 'wikis#git_access'
  get '/wikis/pages', to: 'wikis#pages', as: 'wiki_pages'
  post '/wikis', to: 'wikis#create'

  get '/wikis/*id/history', to: 'wikis#history', as: 'wiki_history', constraints: WIKI_SLUG_ID
  get '/wikis/*id/edit', to: 'wikis#edit', as: 'wiki_edit', constraints: WIKI_SLUG_ID

  get '/wikis/*id', to: 'wikis#show', as: 'wiki', constraints: WIKI_SLUG_ID
  delete '/wikis/*id', to: 'wikis#destroy', constraints: WIKI_SLUG_ID
  put '/wikis/*id', to: 'wikis#update', constraints: WIKI_SLUG_ID
  post '/wikis/*id/preview_markdown', to: 'wikis#preview_markdown', constraints: WIKI_SLUG_ID, as: 'wiki_preview_markdown'
end
