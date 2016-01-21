require 'active_support/core_ext/string/output_safety'
require 'html/pipeline/filter'

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
      def self.user_can_see_reference?(user, node, context)
        if node.has_attribute?('data-project')
          project_id = node.attr('data-project').to_i
          return true if project_id == context[:project].try(:id)

          project = Project.find(project_id) rescue nil
          Ability.abilities.allowed?(user, :read_project, project)
        else
          true
        end
      end

      def self.user_can_reference?(user, node, context)
        true
      end

      def self.referenced_by(node)
        raise NotImplementedError, "#{self} does not implement #{__method__}"
      end

      # Returns a data attribute String to attach to a reference link
      #
      # attributes - Hash, where the key becomes the data attribute name and the
      #              value is the data attribute value
      #
      # Examples:
      #
      #   data_attribute(project: 1, issue: 2)
      #   # => "data-reference-filter=\"SomeReferenceFilter\" data-project=\"1\" data-issue=\"2\""
      #
      #   data_attribute(project: 3, merge_request: 4)
      #   # => "data-reference-filter=\"SomeReferenceFilter\" data-project=\"3\" data-merge-request=\"4\""
      #
      # Returns a String
      def data_attribute(attributes = {})
        attributes[:reference_filter] = self.class.name.demodulize
        attributes.map { |key, value| %Q(data-#{key.to_s.dasherize}="#{escape_once(value)}") }.join(" ")
      end

      def escape_once(html)
        html.html_safe? ? html : ERB::Util.html_escape_once(html)
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

      def reference_class(type)
        "gfm gfm-#{type}"
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
      # Returns the updated Nokogiri::HTML::DocumentFragment object.
      def replace_text_nodes_matching(pattern)
        return doc if project.nil?

        search_text_nodes(doc).each do |node|
          next if ignored_ancestry?(node)
          next unless node.text =~ pattern

          content = node.to_html

          html = yield content

          next if html == content

          node.replace(html)
        end

        doc
      end

      # Iterate through the document's link nodes, yielding the current node's
      # content if:
      #
      # * The `project` context value is present AND
      # * The node's content matches `pattern`
      #
      # pattern - Regex pattern against which to match the node's content
      #
      # Yields the current node's String contents. The result of the block will
      # replace the node and update the current document.
      #
      # Returns the updated Nokogiri::HTML::DocumentFragment object.
      def replace_link_nodes_with_text(pattern)
        return doc if project.nil?

        doc.xpath('descendant-or-self::a').each do |node|
          klass = node.attr('class')
          next if klass && klass.include?('gfm')

          link = node.attr('href')
          text = node.text

          next unless link && text

          link = CGI.unescape(link)
          next unless link.force_encoding('UTF-8').valid_encoding?
          # Ignore ending punctionation like periods or commas
          next unless link == text && text =~ /\A#{pattern}/

          html = yield text

          next if html == text

          node.replace(html)
        end

        doc
      end

      # Iterate through the document's link nodes, yielding the current node's
      # content if:
      #
      # * The `project` context value is present AND
      # * The node's HREF matches `pattern`
      #
      # pattern - Regex pattern against which to match the node's HREF
      #
      # Yields the current node's String HREF and String content.
      # The result of the block will replace the node and update the current document.
      #
      # Returns the updated Nokogiri::HTML::DocumentFragment object.
      def replace_link_nodes_with_href(pattern)
        return doc if project.nil?

        doc.xpath('descendant-or-self::a').each do |node|
          klass = node.attr('class')
          next if klass && klass.include?('gfm')

          link = node.attr('href')
          text = node.text

          next unless link && text
          link = CGI.unescape(link)
          next unless link.force_encoding('UTF-8').valid_encoding?
          next unless link && link =~ /\A#{pattern}\z/

          html = yield link, text

          next if html == link

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
