class Public::SnippetsController < ApplicationController
  skip_before_filter :authenticate_user!,
    :reject_blocked, :set_current_user_for_observers,
    :add_abilities

  layout 'public'

  def index
    @snippets = Snippet.public_only
  end

  def show

    @snippet = Snippet.where(:public_hashkey => params[:id]).first
  
    not_found if @snippet.nil?

    send_data(
      @snippet.content,
      type: "text/plain",
      disposition: 'inline',
      filename: @snippet.file_name
    )

  end

  protected

  def not_found
    # render :status => 404
    raise ActionController::RoutingError.new("Not Found")
  end

end
