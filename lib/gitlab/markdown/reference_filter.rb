require 'active_support/core_ext/string/output_safety'
require 'html/pipeline'

module Gitlab
  module Markdown
    # Base class for GitLab Flavored Markdown reference filters.
    #
    # References within <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # Context options:
    #   :project (required) - Current project, ignored if reference is cross-project.
    #   :reference_class    - Custom CSS class added to reference links.
    #   :only_path          - Generate path-only links.
    #
    class ReferenceFilter < HTML::Pipeline::Filter
      def escape_once(html)
        ERB::Util.html_escape_once(html)
      end

      # Don't look for references in text nodes that are children of these
      # elements.
      IGNORE_PARENTS = %w(pre code a style).to_set

      def ignored_ancestry?(node)
        has_ancestor?(node, IGNORE_PARENTS)
      end

      def project
        context[:project]
      end

      def reference_class(type)
        "gfm gfm-#{type} #{context[:reference_class]}".strip
      end

      # Iterate through the document's text nodes, yielding the current node's
      # content if:
      #
      # * The `project` context value is present AND
      # * The node's content matches `pattern` AND
      # * The node is not an ancestor of an ignored node type
      #
      # pattern - Regex pattern against which to match the node's content
      #
      # Yields the current node's String contents. The result of the block will
      # replace the node's existing content and update the current document.
      #
      # Returns the updated Nokogiri::XML::Document object.
      def replace_text_nodes_matching(pattern)
        return doc if project.nil?

        search_text_nodes(doc).each do |node|
          content = node.to_html

          next unless content.match(pattern)
          next if ignored_ancestry?(node)

          html = yield content

          next if html == content

          node.replace(html)
        end

        doc
      end

      # Ensure that a :project key exists in context
      #
      # Note that while the key might exist, its value could be nil!
      def validate
        needs :project
      end
    end
  end
end
