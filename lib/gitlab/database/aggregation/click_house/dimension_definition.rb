# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class DimensionDefinition < PartDefinition
          attr_reader :association

          def initialize(*args, association: false, **kwargs)
            super
            @association = association == true ? {} : association
          end

          def association?
            !!association
          end

          def to_inner_arel(context)
            expression ? expression.call : context[:scope][name]
          end

          def to_outer_arel(context)
            Arel::Table.new(context[:inner_query_name])[context.fetch(:local_alias, name)]
          end
        end
      end
    end
  end
end
