# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module SchemaObjects
        class Trigger < Base
          def initialize(parsed_stmt, function_body: nil)
            super(parsed_stmt)
            @function_body = function_body
          end

          def name
            parsed_stmt.trigname
          end

          # Source of the trigger function, read from the database only.
          attr_reader :function_body
        end
      end
    end
  end
end
