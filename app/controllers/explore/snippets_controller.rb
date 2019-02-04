# frozen_string_literal: true

class Explore::SnippetsController < Explore::ApplicationController
  def index
    @snippets = SnippetsFinder.new(current_user).execute
    @snippets = @snippets.page(params[:page])
  end
end
