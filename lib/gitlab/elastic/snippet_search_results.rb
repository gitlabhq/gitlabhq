module Gitlab
  module Elastic
    class SnippetSearchResults < ::Gitlab::SnippetSearchResults
      def objects(scope, page = nil)
        case scope
        when 'snippet_titles'
          snippet_titles.records.page(page).per(per_page)
        when 'snippet_blobs'
          snippet_blobs.records.page(page).per(per_page)
        else
          super
        end
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
    end
  end
end
