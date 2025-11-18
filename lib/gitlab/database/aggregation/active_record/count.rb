# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ActiveRecord
        class Count < Column
          def initialize(name = nil, type = :integer, formatter: nil, description: nil)
            super
          end

          def to_hash
            super.merge(kind: :column)
          end

          def identifier
            :count
          end

          def to_arel(_context)
            Arel::Nodes::Count.new([Arel.star])
          end
        end
      end
    end
  end
end
