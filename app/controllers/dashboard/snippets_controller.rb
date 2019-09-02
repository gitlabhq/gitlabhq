# frozen_string_literal: true

class Dashboard::SnippetsController < Dashboard::ApplicationController
  include Gitlab::NoteableMetadata

  skip_cross_project_access_check :index

  def index
    @snippets = SnippetsFinder.new(current_user, author: current_user, scope: params[:scope])
      .execute
      .page(params[:page])
      .inc_author

    @noteable_meta_data = noteable_meta_data(@snippets, 'Snippet')
  end
end
