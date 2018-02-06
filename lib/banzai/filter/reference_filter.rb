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

      class << self
        attr_accessor :reference_type
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
        attributes[:placement] ||= 'bottom'
        attributes.delete(:original) if context[:no_original_data]
        attributes.map do |key, value|
          %Q(data-#{key.to_s.dasherize}="#{escape_once(value)}")
        end.join(' ')
      end

      def escape_once(html)
        html.html_safe? ? html : ERB::Util.html_escape_once(html)
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

      def skip_project_check?
        context[:skip_project_check]
      end

      def reference_class(type)
        "gfm gfm-#{type} has-tooltip"
      end

      # Ensure that a :project key exists in context
      #
      # Note that while the key might exist, its value could be nil!
      def validate
        needs :project
      end

      # Iterates over all <a> and text() nodes in a document.
      #
      # Nodes are skipped whenever their ancestor is one of the nodes returned
      # by `ignore_ancestor_query`. Link tags are not processed if they have a
      # "gfm" class or the "href" attribute is empty.
      def each_node
        return to_enum(__method__) unless block_given?

        query = %Q{descendant-or-self::text()[not(#{ignore_ancestor_query})]
        | descendant-or-self::a[
          not(contains(concat(" ", @class, " "), " gfm ")) and not(@href = "")
        ]}

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
        link = CGI.unescape(node.attr('href').to_s)
        inner_html = node.inner_html

        return unless link.force_encoding('UTF-8').valid_encoding?

        yield link, inner_html
      end

      def replace_text_when_pattern_matches(node, pattern)
        return unless node.text =~ pattern

        content = node.to_html
        html = yield content

        node.replace(html) unless content == html
      end

      def replace_link_node_with_text(node, link)
        html = yield

        node.replace(html) unless html == node.text
      end

      def replace_link_node_with_href(node, link)
        html = yield

        node.replace(html) unless html == link
      end

      def text_node?(node)
        node.is_a?(Nokogiri::XML::Text)
      end

      def element_node?(node)
        node.is_a?(Nokogiri::XML::Element)
      end
    end
  end
end
