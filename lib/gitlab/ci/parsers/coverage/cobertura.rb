# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Coverage
        class Cobertura
          InvalidXMLError = Class.new(Gitlab::Ci::Parsers::ParserError)
          InvalidLineInformationError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def parse!(xml_data, coverage_report, project_path: nil, worktree_paths: nil)
            if Feature.enabled?(:use_cobertura_sax_parser, default_enabled: :yaml)
              Nokogiri::XML::SAX::Parser.new(SaxDocument.new(coverage_report, project_path, worktree_paths)).parse(xml_data)
            else
              DomParser.new.parse(xml_data, coverage_report, project_path, worktree_paths)
            end
          end
        end
      end
    end
  end
end
