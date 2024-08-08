# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      ParserNotFoundError = Class.new(ParserError)

      def self.parsers
        {
          junit: ::Gitlab::Ci::Parsers::Test::Junit,
          cobertura: ::Gitlab::Ci::Parsers::Coverage::Cobertura,
          terraform: ::Gitlab::Ci::Parsers::Terraform::Tfplan,
          accessibility: ::Gitlab::Ci::Parsers::Accessibility::Pa11y,
          jacoco: ::Gitlab::Ci::Parsers::Coverage::Jacoco,
          codequality: ::Gitlab::Ci::Parsers::Codequality::CodeClimate,
          sast: ::Gitlab::Ci::Parsers::Security::Sast,
          secret_detection: ::Gitlab::Ci::Parsers::Security::SecretDetection,
          cyclonedx: ::Gitlab::Ci::Parsers::Sbom::Cyclonedx
        }
      end

      def self.fabricate!(file_type, *args, **kwargs)
        parsers.fetch(file_type.to_sym).new(*args, **kwargs)
      rescue KeyError
        raise ParserNotFoundError, "Cannot find any parser matching file type '#{file_type}'"
      end

      def self.instrument!
        parsers.values.each { |parser_class| parser_class.prepend(Parsers::Instrumentation) }
      end
    end
  end
end

Gitlab::Ci::Parsers.prepend_mod_with('Gitlab::Ci::Parsers')
