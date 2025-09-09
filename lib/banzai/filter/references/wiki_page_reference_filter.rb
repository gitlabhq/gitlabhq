# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # HTML filter that replaces wiki page references with links.
      #
      # This filter supports cross-project and cross-group references.
      class WikiPageReferenceFilter < AbstractReferenceFilter
        include CrossNamespaceReference

        self.reference_type = :wiki_page
        self.object_class   = ::WikiPage

        def find_object(parent_object, id)
          parent_object.wiki.find_page(id, load_content: false)
        end

        def parse_symbol(string, _match)
          string
        end

        def url_for_object(object, parent_object)
          Gitlab::UrlBuilder.wiki_page_url(parent_object.wiki, object)
        end

        def parent_type
          :namespace
        end

        def parent
          project&.project_namespace || group
        end
      end
    end
  end
end
