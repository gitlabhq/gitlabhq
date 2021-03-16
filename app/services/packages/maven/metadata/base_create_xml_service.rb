# frozen_string_literal: true

module Packages
  module Maven
    module Metadata
      class BaseCreateXmlService
        include Gitlab::Utils::StrongMemoize

        INDENT_SPACE = 2

        def initialize(metadata_content:, package:)
          @metadata_content = metadata_content
          @package = package
        end

        private

        def xml_doc
          strong_memoize(:xml_doc) do
            Nokogiri::XML(@metadata_content) do |config|
              config.default_xml.noblanks
            end
          end
        end

        def xml_node(name, content)
          xml_doc.create_element(name).tap { |e| e.content = content }
        end
      end
    end
  end
end
