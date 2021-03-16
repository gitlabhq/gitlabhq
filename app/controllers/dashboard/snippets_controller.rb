# frozen_string_literal: true

class Dashboard::SnippetsController < Dashboard::ApplicationController
  include PaginatedCollection
  include Gitlab::NoteableMetadata
  include SnippetsSort

  skip_cross_project_access_check :index

  feature_category :snippets

  def index
    @snippet_counts = Snippets::CountService
      .new(current_user, author: current_user)
      .execute

    @snippets = SnippetsFinder.new(current_user, author: current_user, scope: params[:scope], sort: sort_param)
      .execute
      .page(params[:page])
      .inc_author
      .inc_projects_namespace_route
      .inc_statistics

    return if redirect_out_of_range(@snippets)

    @noteable_meta_data = noteable_meta_data(@snippets, 'Snippet')
  end
end
