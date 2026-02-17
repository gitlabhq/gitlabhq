# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class Mean < MetricDefinition
          def initialize(name, type = :float, *args, **kwargs)
            super
          end

          def identifier
            :"mean_#{name}"
          end

          def to_arel(context)
            super.average
          end
        end
      end
    end
  end
end
