scope(controller: :wikis) do
  scope(path: 'wikis', as: :wikis) do
    get :git_access
    get :pages
    get :new
    get '/', to: redirect('%{namespace_id}/%{project_id}/wikis/home')
    post '/', to: 'wikis#create'
  end

  scope(path: 'wikis/*id', as: :wiki, format: false) do
    get :edit
    get :history
    post :preview_markdown
    get '/', action: :show
    put '/', action: :update
    delete '/', action: :destroy
  end
end
