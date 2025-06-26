# frozen_string_literal: true

module Namespaces
  module Traversal
    module Traversable
      extend ActiveSupport::Concern

      included do
        scope :within, ->(traversal_ids) do
          validated_ids = traversal_ids.map { |id| Integer(id) }

          where(
            "#{arel_table.name}.traversal_ids >= ARRAY[?]::bigint[] " \
              "AND next_traversal_ids_sibling(ARRAY[?]::bigint[]) > #{arel_table.name}.traversal_ids",
            validated_ids, validated_ids
          )
        end
      end
    end
  end
end
