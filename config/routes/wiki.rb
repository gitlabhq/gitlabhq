scope(controller: :wikis) do
  scope(path: 'wikis/pages', as: :wiki_pages, format: false) do
    get :new, to: 'wiki_pages#new'
    post '/', to: 'wiki_pages#create'
  end

  scope(path: 'wikis', as: :wikis) do
    get :git_access
    get :pages
    get '/', to: redirect('%{namespace_id}/%{project_id}/-/wiki_pages/home')
    get '/*id', to: redirect('%{namespace_id}/%{project_id}/-/wiki_pages/%{id}')
  end

  scope(path: '-/wiki_pages', as: :wiki_page, format: false) do
    post '/', to: 'wiki_pages#create'
  end

  scope(path: '-/wiki_pages/*id', as: :wiki, format: false, controller: :wiki_pages) do
    get :edit
    get :history
    post :preview_markdown
    get '/', action: :show
    put '/', action: :update
    delete '/', action: :destroy
  end

  scope(path: '-/wiki_dirs/*id', as: :wiki_dir, format: false, controller: :wiki_directories) do
    get '/', action: :show
  end
end
