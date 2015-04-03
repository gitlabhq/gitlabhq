require 'html/pipeline'

module Gitlab
  module Markdown
    # HTML filter that replaces label references with links. References within
    # <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # Context options:
    #   :project (required) - Current project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class LabelReferenceFilter < HTML::Pipeline::Filter
      # Public: Find label references in text
      #
      #   LabelReferenceFilter.references_in(text) do |match, label|
      #     "<a href=...>#{label}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match and the Integer label ID.
      #
      # Returns a String replaced with the return of the block.
      def self.references_in(text)
        text.gsub(LABEL_PATTERN) do |match|
          yield match, $~[:label].to_i
        end
      end

      # Pattern used to extract label references from text
      #
      # This pattern supports cross-project references.
      LABEL_PATTERN = /~(?<label>\d+)/

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def call
        doc.search('text()').each do |node|
          content = node.to_html

          next if project.nil?
          next unless content.match(LABEL_PATTERN)
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = label_link_filter(content)

          next if html == content

          node.replace(html)
        end

        doc
      end

      def validate
        needs :project
      end

      # Replace label references in text with links to the label specified.
      #
      # text - String text to replace references in.
      #
      # Returns a String with label references replaced with links. All links
      # have `gfm` and `gfm-label` class names attached for styling.
      def label_link_filter(text)
        project = context[:project]

        self.class.references_in(text) do |match, id|
          if label = project.labels.find_by(id: id)
            url = url_for_label(project, label)

            klass = "gfm gfm-label #{context[:reference_class]}".strip

            %(<a href="#{url}" class="#{klass}">#{render_colored_label(label)}</a>)
          else
            match
          end
        end
      end

      def url_for_label(project, label)
        h = Rails.application.routes.url_helpers
        h.namespace_project_issues_path(project.namespace, project,
                                        label_name: label.name,
                                        only_path: context[:only_path])
      end

      def render_colored_label(label)
        LabelsHelper.render_colored_label(label)
      end

      def project
        context[:project]
      end
    end
  end
end
