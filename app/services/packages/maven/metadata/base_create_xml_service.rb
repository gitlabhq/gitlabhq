# frozen_string_literal: true

module Packages
  module Maven
    module Metadata
      class BaseCreateXmlService
        include Gitlab::Utils::StrongMemoize

        INDENT_SPACE = 2

        def initialize(metadata_content:, package:, logger: nil)
          @metadata_content = metadata_content
          @package = package
          @logger = logger || Gitlab::AppJsonLogger
        end

        private

        attr_reader :logger

        def xml_doc
          Nokogiri::XML(@metadata_content) do |config|
            config.default_xml.noblanks
          end
        end
        strong_memoize_attr :xml_doc

        def xml_node(name, content)
          xml_doc.create_element(name).tap { |e| e.content = content }
        end
      end
    end
  end
end
