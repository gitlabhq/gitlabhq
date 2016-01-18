module Gitlab
  module Elastic
    class SnippetSearchResults < SearchResults
      include SnippetsHelper

      attr_reader :limit_snippet_ids

      def initialize(limit_snippet_ids, query)
        @limit_snippet_ids = limit_snippet_ids
        @query = query
      end

      def objects(scope, page = nil)
        case scope
        when 'snippet_titles'
          snippet_titles.records.page(page).per(per_page)
        when 'snippet_blobs'
          # We process whole list of items then paginate it. Not too smart
          # Should be refactored in the CE side first to prevent conflicts hell
          Kaminari.paginate_array(
            snippet_blobs.records.map do |snippet|
              chunk_snippet(snippet)
            end
          ).page(page).per(per_page)
        else
          super
        end
      end

      def total_count
        @total_count ||= snippet_titles_count + snippet_blobs_count
      end

      def snippet_titles_count
        @snippet_titles_count ||= snippet_titles.total_count
      end

      def snippet_blobs_count
        @snippet_blobs_count ||= snippet_blobs.total_count
      end

      private

      def snippet_titles
        opt = {
          ids: limit_snippet_ids
        }

        Snippet.elastic_search(query, options: opt)
      end

      def snippet_blobs
        opt = {
          ids: limit_snippet_ids
        }

        Snippet.elastic_search_code(query, options: opt)
      end

      def default_scope
        'snippet_blobs'
      end
    end
  end
end
