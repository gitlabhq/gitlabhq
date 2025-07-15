# frozen_string_literal: true

module Namespaces
  module Traversal
    module Traversable
      extend ActiveSupport::Concern

      included do
        scope :within, ->(traversal_ids) do
          validated_ids = traversal_ids.map { |id| Integer(id) }
          traversal_ids_literal = "{#{validated_ids.join(',')}}"
          next_traversal_ids_literal = "{#{validated_ids.dup.tap { |ids| ids[-1] += 1 }.join(',')}}"

          where(
            "#{arel_table.name}.traversal_ids >= ? AND ? > #{arel_table.name}.traversal_ids",
            traversal_ids_literal, next_traversal_ids_literal
          )
        end
      end
    end
  end
end
