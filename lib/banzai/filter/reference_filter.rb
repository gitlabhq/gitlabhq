# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/reference.js
module Banzai
  module Filter
    # Base class for GitLab Flavored Markdown reference filters.
    #
    # References within <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # Context options:
    #   :project (required) - Current project, ignored if reference is cross-project.
    #   :only_path          - Generate path-only links.
    class ReferenceFilter < HTML::Pipeline::Filter
      include RequestStoreReferenceCache
      include OutputSafety

      class << self
        attr_accessor :reference_type

        def call(doc, context = nil, result = nil)
          new(doc, context, result).call_and_update_nodes
        end
      end

      def initialize(doc, context = nil, result = nil)
        super

        @new_nodes = {}
        @nodes = self.result[:reference_filter_nodes]
      end

      def call_and_update_nodes
        with_update_nodes { call }
      end

      # Returns a data attribute String to attach to a reference link
      #
      # attributes - Hash, where the key becomes the data attribute name and the
      #              value is the data attribute value
      #
      # Examples:
      #
      #   data_attribute(project: 1, issue: 2)
      #   # => "data-reference-type=\"SomeReferenceFilter\" data-project=\"1\" data-issue=\"2\""
      #
      #   data_attribute(project: 3, merge_request: 4)
      #   # => "data-reference-type=\"SomeReferenceFilter\" data-project=\"3\" data-merge-request=\"4\""
      #
      # Returns a String
      def data_attribute(attributes = {})
        attributes = attributes.reject { |_, v| v.nil? }

        attributes[:reference_type] ||= self.class.reference_type
        attributes[:container] ||= 'body'
        attributes[:placement] ||= 'top'
        attributes.delete(:original) if context[:no_original_data]
        attributes.map do |key, value|
          %Q(data-#{key.to_s.dasherize}="#{escape_once(value)}")
        end.join(' ')
      end

      def ignore_ancestor_query
        @ignore_ancestor_query ||= begin
          parents = %w(pre code a style)
          parents << 'blockquote' if context[:ignore_blockquotes]

          parents.map { |n| "ancestor::#{n}" }.join(' or ')
        end
      end

      def project
        context[:project]
      end

      def group
        context[:group]
      end

      def user
        context[:user]
      end

      def skip_project_check?
        context[:skip_project_check]
      end

      def reference_class(type, tooltip: true)
        gfm_klass = "gfm gfm-#{type}"

        return gfm_klass unless tooltip

        "#{gfm_klass} has-tooltip"
      end

      # Ensure that a :project key exists in context
      #
      # Note that while the key might exist, its value could be nil!
      def validate
        needs :project unless skip_project_check?
      end

      # Iterates over all <a> and text() nodes in a document.
      #
      # Nodes are skipped whenever their ancestor is one of the nodes returned
      # by `ignore_ancestor_query`. Link tags are not processed if they have a
      # "gfm" class or the "href" attribute is empty.
      def each_node
        return to_enum(__method__) unless block_given?

        doc.xpath(query).each do |node|
          yield node
        end
      end

      # Returns an Array containing all HTML nodes.
      def nodes
        @nodes ||= each_node.to_a
      end

      # Yields the link's URL and inner HTML whenever the node is a valid <a> tag.
      def yield_valid_link(node)
        link = unescape_link(node.attr('href').to_s)
        inner_html = node.inner_html

        return unless link.force_encoding('UTF-8').valid_encoding?

        yield link, inner_html
      end

      def unescape_link(href)
        CGI.unescape(href)
      end

      def replace_text_when_pattern_matches(node, index, pattern)
        return unless node.text =~ pattern

        content = node.to_html
        html = yield content

        replace_text_with_html(node, index, html) unless html == content
      end

      def replace_link_node_with_text(node, index)
        html = yield

        replace_text_with_html(node, index, html) unless html == node.text
      end

      def replace_link_node_with_href(node, index, link)
        html = yield

        replace_text_with_html(node, index, html) unless html == link
      end

      def text_node?(node)
        node.is_a?(Nokogiri::XML::Text)
      end

      def element_node?(node)
        node.is_a?(Nokogiri::XML::Element)
      end

      private

      def query
        @query ||= %Q{descendant-or-self::text()[not(#{ignore_ancestor_query})]
        | descendant-or-self::a[
          not(contains(concat(" ", @class, " "), " gfm ")) and not(@href = "")
        ]}
      end

      def replace_text_with_html(node, index, html)
        replace_and_update_new_nodes(node, index, html)
      end

      def replace_and_update_new_nodes(node, index, html)
        previous_node = node.previous
        next_node = node.next
        parent_node = node.parent
        # Unfortunately node.replace(html) returns re-parented nodes, not the actual replaced nodes in the doc
        # We need to find the actual nodes in the doc that were replaced
        node.replace(html)
        @new_nodes[index] = []

        # We replaced node with new nodes, so we find first new node. If previous_node is nil, we take first parent child
        new_node = previous_node ? previous_node.next : parent_node&.children&.first

        # We iterate from first to last replaced node and store replaced nodes in @new_nodes
        while new_node && new_node != next_node
          @new_nodes[index] << new_node.xpath(query)
          new_node = new_node.next
        end

        @new_nodes[index].flatten!
      end

      def only_path?
        context[:only_path]
      end

      def with_update_nodes
        @new_nodes = {}
        yield.tap { update_nodes! }
      end

      # Once Filter completes replacing nodes, we update nodes with @new_nodes
      def update_nodes!
        @new_nodes.sort_by { |index, _new_nodes| -index }.each do |index, new_nodes|
          nodes[index, 1] = new_nodes
        end
        result[:reference_filter_nodes] = nodes
      end
    end
  end
end
