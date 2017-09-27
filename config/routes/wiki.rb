scope(controller: :wikis) do
  scope(path: 'wikis', as: :wikis) do
    get :git_access
    get :pages
    get '/', to: redirect('/%{namespace_id}/%{project_id}/wikis/home')
    post '/', to: 'wikis#create'
  end

  # Note, we use "format: false" and "defaults: { format: :html }" parameters together
  # While it can be confusing it's absolutelly needed to make it behave like Rails 4.
  # See https://github.com/rails/rails/issues/28901
  scope(path: 'wikis/*id', as: :wiki, format: false, defaults: { format: :html }) do
    get :edit
    get :history
    post :preview_markdown
    get '/', action: :show
    put '/', action: :update
    delete '/', action: :destroy
  end
end
