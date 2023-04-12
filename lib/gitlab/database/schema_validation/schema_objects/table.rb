# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module SchemaObjects
        class Table
          def initialize(name)
            @name = name
          end

          def table_name
            name
          end

          def statement
            nil
          end

          attr_reader :name
        end
      end
    end
  end
end
