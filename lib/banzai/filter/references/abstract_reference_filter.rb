# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # Issues, merge requests, Snippets, Commits and Commit Ranges share
      # similar functionality in reference filtering.
      class AbstractReferenceFilter < ReferenceFilter
        include CrossProjectReference
        prepend Concerns::TimeoutFilterHandler
        prepend Concerns::PipelineTimingCheck

        def initialize(doc, context = nil, result = nil)
          super

          @reference_cache = ReferenceCache.new(self, context, result)
        end

        # See ReferenceFilter#references_in for requirements on the input, block,
        # and return value of this function.
        #
        # This function yields the String match, the Integer referenced object ID, an optional String
        # of the external project reference, an optional String of the namespace reference,
        # and the full MatchData.
        def references_in(text, pattern = object_class.reference_pattern)
          replace_references_in_text_with_html(Gitlab::Utils::Gsub.gsub_with_limit(text, pattern,
            limit: Banzai::Filter::FILTER_ITEM_LIMIT)) do |match_data|
            if ident = identifier(match_data)
              yield match_data[0], ident, match_data.named_captures['project'],
                 match_data.named_captures['namespace'], match_data
            end
          end
        end

        def identifier(match_data)
          symbol = symbol_from_match_data(match_data)

          parse_symbol(symbol, match_data) if object_class.reference_valid?(symbol)
        end

        def symbol_from_match_data(match_data)
          key = object_sym
          match_data[key] if match_data.names.include?(key.to_s)
        end

        # Transform a symbol extracted from the text to a meaningful value
        # In most cases these will be integers, so we call #to_i by default
        #
        # This method has the contract that if a string `ref` refers to a
        # record `record`, then `parse_symbol(ref) == record_identifier(record)`.
        def parse_symbol(symbol, match_data)
          symbol.to_i
        end

        # We assume that most classes are identifying records by ID.
        #
        # This method has the contract that if a string `ref` refers to a
        # record `record`, then `class.parse_symbol(ref) == record_identifier(record)`.
        def record_identifier(record)
          record.id
        end

        # Implement in child class
        # Example: project.merge_requests.find
        def find_object(parent_object, id)
          raise NotImplementedError, "#{self.class} must implement method: #{__callee__}"
        end

        # Override if the link reference pattern produces a different ID (global
        # ID vs internal ID, for instance) to the regular reference pattern.
        def find_object_from_link(parent_object, id)
          find_object(parent_object, id)
        end

        # Implement in child class
        # Example: project_merge_request_url
        def url_for_object(object, parent_object)
          raise NotImplementedError, "#{self.class} must implement method: #{__callee__}"
        end

        def find_object_cached(parent_object, id)
          cached_call(:banzai_find_object, id, path: [object_class, parent_object.id]) do
            find_object(parent_object, id)
          end
        end

        def find_object_from_link_cached(parent_object, id)
          cached_call(:banzai_find_object_from_link, id, path: [object_class, parent_object.id]) do
            find_object_from_link(parent_object, id)
          end
        end

        def from_ref_cached(ref)
          cached_call(:"banzai_#{parent_type}_refs", ref) do
            parent_from_ref(ref)
          end
        end

        def url_for_object_cached(object, parent_object)
          cached_call(:banzai_url_for_object, object, path: [object_class, parent_object.id]) do
            url_for_object(object, parent_object)
          end
        end

        def call
          return doc unless project || group || user

          reference_cache.load_reference_cache(nodes) if respond_to?(:parent_records) && nodes.present?

          ref_pattern = object_reference_pattern
          link_pattern = object_class.link_reference_pattern

          # Compile often used regexps only once outside of the loop
          ref_pattern_anchor = /\A#{ref_pattern}\z/
          link_pattern_start = /\A#{link_pattern}/
          link_pattern_anchor = /\A#{link_pattern}\z/

          nodes.each_with_index do |node, index|
            if text_node?(node) && ref_pattern
              replace_node_when_text_matches(node, index, ref_pattern) do |content|
                object_link_filter(content, ref_pattern)
              end

            elsif element_node?(node)
              yield_valid_link(node) do |link, text, inner_html|
                if ref_pattern && link =~ ref_pattern_anchor
                  html = object_link_filter(link, ref_pattern_anchor, link_content_html: inner_html)
                  replace_node_with_html(node, index, html) if html

                  next
                end

                next unless link_pattern

                if link == text && text =~ link_pattern_start
                  html = object_link_filter(text, link_pattern_start, link_reference: true)
                  replace_node_with_html(node, index, html) if html

                  next
                end

                if link_pattern_anchor.match?(link)
                  html = object_link_filter(link, link_pattern_anchor, link_content_html: inner_html,
                    link_reference: true)
                  replace_node_with_html(node, index, html) if html

                  next
                end
              end
            end
          end

          doc
        end

        # Replace references (like `!123` for merge requests) in text with links
        # to the referenced object's details page.
        #
        # text - String text to replace references in.
        # pattern - Reference pattern to match against.
        # link_content_html - Original HTML content of the link being replaced.
        # link_reference - True if this was using the link reference pattern,
        #                  false otherwise.
        #
        # Returns String HTML with references replaced with links, or nil if no
        # replacements were made. All links have `gfm` and `gfm-OBJECT_NAME`
        # class names attached for styling.
        #
        # Note carefully:
        #
        # * `text` is text, not HTML.
        # * `link_content_html`, if provided, is HTML.
        # * The return value is HTML (or nil).
        def object_link_filter(text, pattern, link_content_html: nil, link_reference: false)
          references_in(text, pattern) do |match_text, id, project_ref, namespace_ref, matches|
            parent_path = if parent_type == :group
                            reference_cache.full_group_path(namespace_ref)
                          elsif parent_type == :namespace
                            reference_cache.full_namespace_path(matches)
                          else
                            reference_cache.full_project_path(namespace_ref, project_ref, matches)
                          end

            parent = from_ref_cached(parent_path)
            next unless parent

            object =
              if link_reference
                find_object_from_link_cached(parent, id)
              else
                find_object_cached(parent, id)
              end

            next unless object

            title = object_link_title(object, matches)
            klass = reference_class(object_sym)

            data_attributes = data_attributes_for(
              link_content_html || CGI.escapeHTML(match_text),
              parent,
              object,
              link_content: !!link_content_html,
              link_reference: link_reference
            )
            data_attributes[:reference_format] = matches[:format] if matches.names.include?("format")
            data_attributes.merge!(additional_object_attributes(object))

            data = data_attribute(data_attributes)

            url =
              if matches.names.include?("url") && matches[:url]
                matches[:url]
              else
                url_for_object_cached(object, parent)
              end

            url.chomp!(matches[:format]) if matches.names.include?("format")

            content = context[:link_text] || link_content_html || object_link_text(object, matches)

            link = write_opening_tag("a", {
              "href" => url,
              "title" => title,
              "class" => klass,
              **data
            }) << content.to_s << "</a>"

            wrap_link(link, object)
          end
        end

        def wrap_link(link, object)
          link
        end

        # "link_content" is true when "original" is the inner HTML content, or false when "original"
        # is HTML-escaped plain text representing the link as written.
        def data_attributes_for(original, parent, object, link_content: false, link_reference: false)
          parent_id = case parent
                      when Group
                        { group: parent.id, namespace: parent.id }
                      when Project
                        { project: parent.id }
                      when Namespaces::ProjectNamespace
                        { namespace: parent.id, project: parent.project.id }
                      end

          {
            original: original,
            link: link_content,
            link_reference: link_reference,
            object_sym => object.id
          }.merge(parent_id)
        end

        def object_link_text_extras(object, matches)
          extras = []

          if matches.names.include?("anchor") && matches[:anchor] && matches[:anchor] =~ /\A\#note_(\d+)\z/
            extras << "comment #{Regexp.last_match(1)}"
          end

          extension = matches[:extension] if matches.names.include?("extension")

          extras << extension if extension

          extras
        end

        def object_link_title(object, matches)
          object.title
        end

        def object_link_text(object, matches)
          parent = project || group || user
          text = object.reference_link_text(parent)

          extras = object_link_text_extras(object, matches)
          text += " (#{extras.join(', ')})" if extras.any?

          text
        end

        def parent_type
          :project
        end

        def parent
          parent_type == :project ? project : group
        end

        private

        attr_accessor :reference_cache

        def additional_object_attributes(object)
          {}
        end
      end
    end
  end
end
