require 'active_support/core_ext/string/output_safety'
require 'gitlab/markdown'
require 'html/pipeline/filter'

module Gitlab
  module Markdown
    # Base class for GitLab Flavored Markdown reference filters.
    #
    # References within <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # Context options:
    #   :project (required) - Current project, ignored if reference is cross-project.
    #   :only_path          - Generate path-only links.
    class ReferenceFilter < HTML::Pipeline::Filter
      LazyReference = Struct.new(:klass, :ids) do
        def self.load(refs)
          lazy_references, values = refs.partition { |ref| ref.is_a?(self) }
          
          lazy_values = lazy_references.group_by(&:klass).flat_map do |klass, refs|
            ids = refs.flat_map(&:ids)
            klass.where(id: ids)
          end

          values + lazy_values
        end

        def load
          self.klass.where(id: self.ids)
        end
      end

      def self.user_can_reference?(user, node, context)
        if node.has_attribute?('data-project')
          project_id = node.attr('data-project').to_i
          return true if project_id == context[:project].try(:id)

          project = Project.find(project_id) rescue nil
          Ability.abilities.allowed?(user, :read_project, project)
        else
          true
        end
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
      #   # => "data-reference-filter=\"Gitlab::Markdown::SomeReferenceFilter\" data-project=\"1\" data-issue=\"2\""
      #
      #   data_attribute(project: 3, merge_request: 4)
      #   # => "data-reference-filter=\"Gitlab::Markdown::SomeReferenceFilter\" data-project=\"3\" data-merge-request=\"4\""
      #
      # Returns a String
      def data_attribute(attributes = {})
        attributes[:reference_filter] = self.class.name
        attributes.map { |key, value| %Q(data-#{key.to_s.dasherize}="#{value}") }.join(" ")
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
