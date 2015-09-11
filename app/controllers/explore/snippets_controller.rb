class Explore::SnippetsController < Explore::ApplicationController
  def index
    @snippets = SnippetsFinder.new.execute(current_user, filter: :all)
    @snippets = @snippets.page(params[:page]).per(PER_PAGE)
  end
end
