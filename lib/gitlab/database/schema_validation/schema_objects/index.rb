# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
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
