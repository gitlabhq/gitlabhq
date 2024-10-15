# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/reference.js
module Banzai
  module Filter
    module References
      # Base class for GitLab Flavored Markdown reference filters.
      #
      # References within <pre>, <code>, <a>, and <style> elements are ignored.
      #
      # Context options:
      #   :project (required) - Current project, ignored if reference is cross-project.
      #   :only_path          - Generate path-only links.
      class ReferenceFilter < HTML::Pipeline::Filter
        include RequestStoreReferenceCache
        include Concerns::OutputSafety
        prepend Concerns::PipelineTimingCheck

        REFERENCE_TYPE_DATA_ATTRIBUTE = 'data-reference-type='

        class << self
          # Implement in child class
          # Example: self.reference_type = :merge_request
          attr_accessor :reference_type

          # Implement in child class
          # Example: self.object_class = MergeRequest
          attr_accessor :object_class

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

        def call
          ref_pattern_start = /\A#{object_reference_pattern}\z/

          nodes.each_with_index do |node, index|
            if text_node?(node)
              replace_text_when_pattern_matches(node, index, object_reference_pattern) do |content|
                object_link_filter(content, object_reference_pattern)
              end
            elsif element_node?(node)
              yield_valid_link(node) do |link, inner_html|
                if ref_pattern_start.match?(link)
                  replace_link_node_with_href(node, index, link) do
                    object_link_filter(link, ref_pattern_start, link_content: inner_html)
                  end
                end
              end
            end
          end

          doc
        end

        # Public: Find references in text (like `!123` for merge requests)
        #
        #   references_in(text) do |match, id, project_ref, matches|
        #     object = find_object(project_ref, id)
        #     "<a href=...>#{object.to_reference}</a>"
        #   end
        #
        # text - String text to search.
        #
        # Yields the String match, the Integer referenced object ID, an optional String
        # of the external project reference, and all of the matchdata.
        #
        # Returns a String replaced with the return of the block.
        def references_in(text, pattern = object_reference_pattern)
          raise NotImplementedError, "#{self.class} must implement method: #{__callee__}"
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

        def nodes?
          @nodes.present?
        end

        def object_class
          self.class.object_class
        end

        def project
          context[:project]
        end

        def group
          context[:group]
        end

        def requires_unescaping?
          false
        end

        private

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

          # "data-reference-type=" attribute got moved into a constant because we need
          # to use it on ReferenceRewriter class to detect if the markdown contains any reference
          reference_type_attribute = "#{REFERENCE_TYPE_DATA_ATTRIBUTE}#{escape_once(self.class.reference_type)} "

          attributes[:container] ||= 'body'
          attributes[:placement] ||= 'top'
          attributes.delete(:original) if context[:no_original_data]

          attributes.map do |key, value|
            %(data-#{key.to_s.dasherize}="#{escape_once(value)}")
          end
            .join(' ')
            .prepend(reference_type_attribute)
        end

        def ignore_ancestor_query
          @ignore_ancestor_query ||= begin
            parents = %w[pre code a style]
            parents << 'blockquote' if context[:ignore_blockquotes]
            parents << 'span[contains(concat(" ", @class, " "), " idiff ")]'

            parents.map { |n| "ancestor::#{n}" }.join(' or ')
          end
        end

        # Ensure that a :project key exists in context
        #
        # Note that while the key might exist, its value could be nil!
        def validate
          needs :project unless skip_project_check?
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

        # Yields the link's URL and inner HTML whenever the node is a valid <a> tag.
        def yield_valid_link(node)
          link = unescape_link(node.attr('href').to_s)
          inner_html = node.inner_html

          return unless link.force_encoding('UTF-8').valid_encoding?

          yield link, inner_html
        end

        def unescape_link(href)
          # We cannot use CGI.unescape here because it also converts `+` to spaces.
          # We need to keep the `+` for expanded reference formats.
          Addressable::URI.unescape(href)
        end

        def unescape_html_entities(text)
          CGI.unescapeHTML(text.to_s)
        end

        def escape_html_entities(text)
          CGI.escapeHTML(text.to_s)
        end

        def replace_text_when_pattern_matches(node, index, pattern)
          return if pattern.is_a?(Gitlab::UntrustedRegexp) && !pattern.match?(node.text)
          return if pattern.is_a?(Regexp) && !(pattern =~ node.text)

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

        def object_reference_pattern
          @object_reference_pattern ||= object_class.reference_pattern
        end

        def object_name
          @object_name ||= object_class.name.underscore
        end

        def object_sym
          @object_sym ||= object_name.to_sym
        end

        def object_link_filter(text, pattern, link_content: nil, link_reference: false)
          raise NotImplementedError, "#{self.class} must implement method: #{__callee__}"
        end

        def query
          @query ||= %{descendant-or-self::text()[not(#{ignore_ancestor_query})]
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
          # if we haven't loaded `nodes` yet, don't do it here
          return unless nodes?

          @new_nodes.sort_by { |index, _new_nodes| -index }.each do |index, new_nodes|
            nodes[index, 1] = new_nodes
          end
          result[:reference_filter_nodes] = nodes
        end
      end
    end
  end
end
