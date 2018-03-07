class Dashboard::SnippetsController < Dashboard::ApplicationController
  skip_cross_project_access_check :index

  def index
    @snippets = SnippetsFinder.new(
      current_user,
      author: current_user,
      scope: params[:scope]
    ).execute
    @snippets = @snippets.page(params[:page])
  end
end
