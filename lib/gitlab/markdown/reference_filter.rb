require 'active_support/core_ext/string/output_safety'
require 'html/pipeline/filter'

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
    # Results:
    #   :references - A Hash of references that were found and replaced.
    class ReferenceFilter < HTML::Pipeline::Filter
      def initialize(*args)
        super

        result[:references] = Hash.new { |hash, type| hash[type] = [] }
      end

      # Returns a data attribute String to attach to a reference link
      #
      # id   - Object ID
      # type - Object type (default: :project)
      #
      # Examples:
      #
      #   data_attribute(1)         # => "data-project-id=\"1\""
      #   data_attribute(2, :user)  # => "data-user-id=\"2\""
      #   data_attribute(3, :group) # => "data-group-id=\"3\""
      #
      # Returns a String
      def data_attribute(id, type = :project)
        %Q(data-#{type}-id="#{id}")
      end

      def escape_once(html)
        ERB::Util.html_escape_once(html)
      end

      def ignore_parents
        @ignore_parents ||= begin
          # Don't look for references in text nodes that are children of these
          # elements.
          parents = %w(pre code a style)
          parents << 'blockquote' if context[:ignore_blockquotes]
          parents.to_set
        end
      end

      def ignored_ancestry?(node)
        has_ancestor?(node, ignore_parents)
      end

      def project
        context[:project]
      end

      # Add a reference to the pipeline's result Hash
      #
      # type   - Singular Symbol reference type (e.g., :issue, :user, etc.)
      # values - One or more Objects to add
      def push_result(type, *values)
        return if values.empty?

        result[:references][type].push(*values)
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
