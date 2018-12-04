# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Test
        ParserNotFoundError = Class.new(StandardError)

        PARSERS = {
          junit: ::Gitlab::Ci::Parsers::Test::Junit
        }.freeze

        def self.fabricate!(file_type)
          PARSERS.fetch(file_type.to_sym).new
        rescue KeyError
          raise ParserNotFoundError, "Cannot find any parser matching file type '#{file_type}'"
        end
      end
    end
  end
end
