# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module SchemaObjects
        class Index < Base
          def name
            parsed_stmt.idxname
          end
        end
      end
    end
  end
end
