# frozen_string_literal: true

class Explore::SnippetsController < Explore::ApplicationController
  include Gitlab::NoteableMetadata

  def index
    @snippets = SnippetsFinder.new(current_user, explore: true)
      .execute
      .page(params[:page])
      .without_count
      .inc_author

    @noteable_meta_data = noteable_meta_data(@snippets, 'Snippet')
  end
end
