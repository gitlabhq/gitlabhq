# frozen_string_literal: true

scope(controller: :wikis) do
  scope(path: 'wikis', as: :wikis) do
    get :git_access
    get :pages
    get :templates
    get :new
    get '/', to: redirect { |params, request| "#{request.path}/home" }
    post '/', to: 'wikis#create'
    scope '-' do
      resource :confluence, only: :show
    end
  end

  scope(path: 'wikis/*id', as: :wiki, format: false) do
    get :edit
    get :history
    get :diff
    get :raw
    post :preview_markdown
    get '/', action: :show
    put '/', action: :update
    delete '/', action: :destroy
  end
end
