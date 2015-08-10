module Gitlab
  module Markdown
    # HTML filter that replaces snippet references with links. References to
    # snippets that do not exist are ignored.
    #
    # This filter supports cross-project references.
    class SnippetReferenceFilter < ReferenceFilter
      include CrossProjectReference

      # Public: Find `$123` snippet references in text
      #
      #   SnippetReferenceFilter.references_in(text) do |match, snippet|
      #     "<a href=...>$#{snippet}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the Integer snippet ID, and an optional String
      # of the external project reference.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(Snippet.reference_pattern) do |match|
          yield match, $~[:snippet].to_i, $~[:project]
        end
      end

      def call
        replace_text_nodes_matching(Snippet.reference_pattern) do |content|
          snippet_link_filter(content)
        end
      end

      # Replace `$123` snippet references in text with links to the referenced
      # snippets's details page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `$123` references replaced with links. All links
      # have `gfm` and `gfm-snippet` class names attached for styling.
      def snippet_link_filter(text)
        self.class.references_in(text) do |match, id, project_ref|
          project = self.project_from_ref(project_ref)

          if project && snippet = project.snippets.find_by(id: id)
            push_result(:snippet, snippet)

            title = escape_once("Snippet: #{snippet.title}")
            klass = reference_class(:snippet)
            data  = data_attribute(project.id)

            url = url_for_snippet(snippet, project)

            %(<a href="#{url}" #{data}
                 title="#{title}"
                 class="#{klass}">#{match}</a>)
          else
            match
          end
        end
      end

      def url_for_snippet(snippet, project)
        h = Rails.application.routes.url_helpers
        h.namespace_project_snippet_url(project.namespace, project, snippet,
                                        only_path: context[:only_path])
      end
    end
  end
end
