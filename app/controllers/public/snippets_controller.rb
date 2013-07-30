class Public::SnippetsController < ApplicationController
  skip_before_filter :authenticate_user!,
    :reject_blocked, :set_current_user_for_observers,
    :add_abilities
  before_filter :set_object_type

  layout 'public'

  def index
    @snippets = Snippet.world_public.page(params[:page]).per(20)
  end

  def show
    @snippet = Snippet.world_public.find(params[:id])
    render_404 and return unless @snippet
  end

  def raw
    @snippet = Snippet.world_public.find(params[:id])

    send_data(
      @snippet.content,
      type: "text/plain",
      disposition: 'inline',
      filename: @snippet.file_name
    )
  end

  private
  def set_object_type
    @public_object_type = "Snippets"
  end
end
