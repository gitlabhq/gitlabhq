module Gitlab
  module Elastic
    class SnippetSearchResults < ::Gitlab::SnippetSearchResults
      def initialize(user, query)
        @user = user
        @query = query
      end

      def objects(scope, page = nil)
        case scope
        when 'snippet_titles'
          snippet_titles.page(page).per(per_page).records
        when 'snippet_blobs'
          snippet_blobs.page(page).per(per_page).records
        else
          super
        end
      end

      private

      def snippet_titles
        opt = {
          user: @user
        }

        Snippet.elastic_search(query, options: opt)
      end

      def snippet_blobs
        opt = {
          user: @user
        }

        Snippet.elastic_search_code(query, options: opt)
      end
    end
  end
end
