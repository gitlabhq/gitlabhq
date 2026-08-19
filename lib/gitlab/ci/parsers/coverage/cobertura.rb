# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Coverage
        class Cobertura
          InvalidXMLError = Class.new(Gitlab::Ci::Parsers::ParserError)
          InvalidLineInformationError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def parse!(xml_data, coverage_report, project_path: nil, worktree_paths: nil, **_kwargs)
            # Nokogiri's SAX parser raises a bare RuntimeError on empty input
            return if xml_data.blank?

            Nokogiri::XML::SAX::Parser.new(Documents::CoberturaDocument.new(coverage_report, project_path, worktree_paths)).parse(xml_data)
          end
        end
      end
    end
  end
end
