# frozen_string_literal: true

class Explore::SnippetsController < Explore::ApplicationController
  include PaginatedCollection
  include Gitlab::NoteableMetadata

  def index
    @snippets = SnippetsFinder.new(current_user)
      .execute
      .page(params[:page])
      .inc_author

    return if redirect_out_of_range(@snippets)

    @noteable_meta_data = noteable_meta_data(@snippets, 'Snippet')
  end
end
