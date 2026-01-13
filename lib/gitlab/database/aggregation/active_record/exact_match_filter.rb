# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class ExactMatchFilter < FilterDefinition
          def apply(relation, filter_config)
            relation.where(column(relation).in(filter_config[:values]))
          end
        end
      end
    end
  end
end
