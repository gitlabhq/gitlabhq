# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncConstraints
      module Validators
        class CheckConstraint < Base
          private

          override :constraint_exists?
          def constraint_exists?
            Gitlab::Database::Migrations::ConstraintsHelpers
              .check_constraint_exists?(table_name, name, connection: connection)
          end
        end
      end
    end
  end
end
