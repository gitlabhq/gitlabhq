# frozen_string_literal: true

module Gitlab
  module Sanitizers
    module SVG
      def self.clean(data)
        Loofah.xml_document(data).scrub!(Scrubber.new).to_s
      end

      class Scrubber < Loofah::Scrubber
        # http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#embedding-custom-non-visible-data-with-the-data-*-attributes
        DATA_ATTR_PATTERN = /\Adata-(?!xml)[a-z_][\w.\u00E0-\u00F6\u00F8-\u017F\u01DD-\u02AF-]*\z/u

        def scrub(node)
          unless Whitelist::ALLOWED_ELEMENTS.include?(node.name)
            node.unlink
            return
          end

          valid_attributes = Whitelist::ALLOWED_ATTRIBUTES[node.name]
          return unless valid_attributes

          node.attribute_nodes.each do |attr|
            attr_name = attribute_name_with_namespace(attr)

            if valid_attributes.include?(attr_name)
              attr.unlink if unsafe_href?(attr)
            else
              # Arbitrary data attributes are allowed.
              unless allows_data_attribute?(node) && data_attribute?(attr)
                attr.unlink
              end
            end
          end
        end

        def attribute_name_with_namespace(attr)
          if attr.namespace
            "#{attr.namespace.prefix}:#{attr.name}"
          else
            attr.name
          end
        end

        def allows_data_attribute?(node)
          Whitelist::ALLOWED_DATA_ATTRIBUTES_IN_ELEMENTS.include?(node.name)
        end

        def unsafe_href?(attr)
          attribute_name_with_namespace(attr) == 'xlink:href' && !attr.value.start_with?('#')
        end

        def data_attribute?(attr)
          attr.name.start_with?('data-') && attr.name =~ DATA_ATTR_PATTERN && attr.namespace.nil?
        end
      end
    end
  end
end
