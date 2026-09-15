# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class PartDefinition < ::Gitlab::Database::Aggregation::PartDefinition
          attr_reader :ctes

          def initialize(*args, ctes: nil, **kwargs)
            super(*args, **kwargs)
            @ctes = Array.wrap(ctes).map(&:to_sym).freeze
          end

          def secondary_arel(_context)
            secondary_expression&.call
          end
        end
      end
    end
  end
end
