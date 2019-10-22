# frozen_string_literal: true

module Gitlab
  class SnippetSearchResults < SearchResults
    include SnippetsHelper

    attr_reader :current_user

    def initialize(current_user, query)
      @current_user = current_user
      @query = query
    end

    def objects(scope, page = nil)
      case scope
      when 'snippet_titles'
        paginated_objects(snippet_titles, page)
      when 'snippet_blobs'
        paginated_objects(snippet_blobs, page)
      else
        super(scope, nil, false)
      end
    end

    def formatted_count(scope)
      case scope
      when 'snippet_titles'
        formatted_limited_count(limited_snippet_titles_count)
      when 'snippet_blobs'
        formatted_limited_count(limited_snippet_blobs_count)
      else
        super
      end
    end

    def limited_snippet_titles_count
      @limited_snippet_titles_count ||= limited_count(snippet_titles)
    end

    def limited_snippet_blobs_count
      @limited_snippet_blobs_count ||= limited_count(snippet_blobs)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def snippets
      SnippetsFinder.new(current_user, finder_params)
        .execute
        .includes(:author)
        .reorder(updated_at: :desc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def snippet_titles
      snippets.search(query)
    end

    def snippet_blobs
      snippets.search_code(query)
    end

    def default_scope
      'snippet_blobs'
    end

    def paginated_objects(relation, page)
      relation.page(page).per(per_page)
    end

    def finder_params
      {}
    end
  end
end

Gitlab::SnippetSearchResults.prepend_if_ee('::EE::Gitlab::SnippetSearchResults')
