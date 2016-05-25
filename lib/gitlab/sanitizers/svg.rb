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
          else
            node.attributes.each do |attr_name, attr|
              valid_attributes = Whitelist::ALLOWED_ATTRIBUTES[node.name]

              unless valid_attributes && valid_attributes.include?(attr_name)
                if Whitelist::ALLOWED_DATA_ATTRIBUTES_IN_ELEMENTS.include?(node.name) &&
                    attr_name.start_with?('data-')
                  # Arbitrary data attributes are allowed. Verify that the attribute
                  # is a valid data attribute.
                  attr.unlink unless attr_name =~ DATA_ATTR_PATTERN
                else
                  attr.unlink
                end
              end
            end
          end
        end
      end
    end
  end
end
