# frozen_string_literal: true

module Search
  class SnippetService < Search::GlobalService
    def execute
      Gitlab::SnippetSearchResults.new(current_user, params[:search])
    end

    def scope
      @scope ||= %w[snippet_titles].delete(params[:scope]) { 'snippet_blobs' }
    end
  end
end

Search::SnippetService.prepend_if_ee('::EE::Search::SnippetService')
