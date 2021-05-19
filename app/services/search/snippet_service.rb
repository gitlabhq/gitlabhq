# frozen_string_literal: true

module Search
  class SnippetService < Search::GlobalService
    def execute
      Gitlab::SnippetSearchResults.new(current_user, params[:search])
    end

    def scope
      @scope ||= 'snippet_titles'
    end
  end
end

Search::SnippetService.prepend_mod_with('Search::SnippetService')
