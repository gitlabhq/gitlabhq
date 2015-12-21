class Dashboard::SnippetsController < Dashboard::ApplicationController
  def index
    @snippets = SnippetsFinder.new.execute(
      current_user,
      filter: :by_user,
      user: current_user,
      scope: params[:scope]
    )
    @snippets = @snippets.page(params[:page]).per(PER_PAGE)
  end
end
