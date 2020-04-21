# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      prepend_if_ee('::EE::Gitlab::Ci::Parsers') # rubocop: disable Cop/InjectEnterpriseEditionModule

      ParserNotFoundError = Class.new(ParserError)

      def self.parsers
        {
          junit: ::Gitlab::Ci::Parsers::Test::Junit,
          cobertura: ::Gitlab::Ci::Parsers::Coverage::Cobertura,
          terraform: ::Gitlab::Ci::Parsers::Terraform::Tfplan
        }
      end

      def self.fabricate!(file_type)
        parsers.fetch(file_type.to_sym).new
      rescue KeyError
        raise ParserNotFoundError, "Cannot find any parser matching file type '#{file_type}'"
      end
    end
  end
end
