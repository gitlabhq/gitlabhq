# frozen_string_literal: true

class Explore::SnippetsController < Explore::ApplicationController
  include Gitlab::NoteableMetadata

  feature_category :source_code_management

  def index
    @snippets = SnippetsFinder.new(current_user, explore: true)
      .execute
      .page(pagination_params[:page])
      .without_count
      .inc_author
      .inc_statistics

    @noteable_meta_data = noteable_meta_data(@snippets, 'Snippet')
  end
end
