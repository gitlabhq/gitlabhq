# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
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
