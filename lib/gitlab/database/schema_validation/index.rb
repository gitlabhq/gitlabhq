# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class Index
        def initialize(parsed_stmt)
          @parsed_stmt = parsed_stmt
        end

        def name
          parsed_stmt.idxname
        end

        def statement
          @statement ||= PgQuery.deparse_stmt(parsed_stmt)
        end

        private

        attr_reader :parsed_stmt
      end
    end
  end
end
