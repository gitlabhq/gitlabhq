# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncConstraints
      module Validators
        class ForeignKey < Base
          private

          override :constraint_exists?
          def constraint_exists?
            Gitlab::Database::PostgresForeignKey
              .by_constrained_table_name_or_identifier(table_name)
              .by_name(name)
              .exists?
          end
        end
      end
    end
  end
end
