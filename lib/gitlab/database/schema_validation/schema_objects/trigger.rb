# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      module SchemaObjects
        class Trigger < Base
          def name
            parsed_stmt.trigname
          end
        end
      end
    end
  end
end
