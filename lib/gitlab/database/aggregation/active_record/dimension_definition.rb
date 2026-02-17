# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class DimensionDefinition < PartDefinition
          attr_reader :association

          def initialize(*args, association: false, **kwargs)
            super
            @association = association
          end

          def association?
            !!association
          end

          def to_arel(context)
            expression ? expression.call : context[:scope].arel_table[name]
          end
        end
      end
    end
  end
end
