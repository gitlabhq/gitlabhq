# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class PartDefinition < ::Gitlab::Database::Aggregation::PartDefinition
          def secondary_arel(_context)
            secondary_expression&.call
          end
        end
      end
    end
  end
end
