class Dashboard::SnippetsController < Dashboard::ApplicationController
  def index
    @snippets = SnippetsFinder.new(
      current_user,
      author: current_user,
      scope: params[:scope]
    ).execute
    @snippets = @snippets.page(params[:page])
  end
end
