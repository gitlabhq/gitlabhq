require 'html/pipeline'

module Gitlab
  module Markdown
    # HTML filter that replaces snippet references with links. References within
    # <pre>, <code>, <a>, and <style> elements are ignored. References to
    # snippets that do not exist are ignored.
    #
    # Context options:
    #   :project (required) - Current project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class SnippetReferenceFilter < HTML::Pipeline::Filter
      # Public: Find `$123` snippet references in text
      #
      #   SnippetReferenceFilter.references_in(text) do |match, snippet|
      #     "<a href=...>$#{snippet}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match and the Integer snippet ID.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(SNIPPET_PATTERN) do |match|
          yield match, $~[:snippet].to_i
        end
      end

      # Pattern used to extract `$123` snippet references from text
      SNIPPET_PATTERN = /\$(?<snippet>\d+)/

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if project.nil?
          next unless content.match(SNIPPET_PATTERN)
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = snippet_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      def validate
        needs :project
      end

      # Replace `$123` snippet references in text with links to the referenced
      # snippets's details page.
      #
      # text - String text to replace references in.
      #
      # Returns a String with `$123` references replaced with links. All links
      # have `gfm` and `gfm-snippet` class names attached for styling.
      def snippet_link_filter(text)
        project = context[:project]

        self.class.references_in(text) do |match, id|
          if snippet = project.snippets.find_by(id: id)
            title = "Snippet: #{snippet.title}"
            klass = "gfm gfm-snippet #{context[:reference_class]}".strip

            url = url_for_snippet(snippet, project)

            %(<a href="#{url}"
                 title="#{title}"
                 class="#{klass}">$#{id}</a>)
          else
            match
          end
        end
      end

      def project
        context[:project]
      end

      def url_for_snippet(snippet, project)
        h = Rails.application.routes.url_helpers
        h.namespace_project_snippet_url(project.namespace, project, snippet,
                                        only_path: context[:only_path])
      end
    end
  end
end
