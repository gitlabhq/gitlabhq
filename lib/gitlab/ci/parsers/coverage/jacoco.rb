# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Coverage
        class Jacoco
          InvalidXMLError = Class.new(Gitlab::Ci::Parsers::ParserError)
          FeatureDisabledError = Class.new(Gitlab::Ci::Parsers::ParserError)
          InvalidLineInformationError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def parse!(xml_data, coverage_report, merge_request_paths:, **_kwargs)
            Nokogiri::XML::SAX::Parser.new(Documents::JacocoDocument.new(coverage_report,
              merge_request_paths)).parse(xml_data)
          end
        end
      end
    end
  end
end
