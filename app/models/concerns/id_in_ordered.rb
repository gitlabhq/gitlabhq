# frozen_string_literal: true

module IdInOrdered
  extend ActiveSupport::Concern

  included do
    scope :id_in_ordered, ->(ids) do
      raise ArgumentError, "ids must be an array of integers" unless ids.is_a?(Enumerable) && ids.all?(Integer)

      # No need to sort if no more than 1 and the sorting code doesn't work
      # with an empty array
      return id_in(ids) unless ids.count > 1

      id_attribute = arel_table[:id]
      id_in(ids)
        .order(
          Arel.sql("array_position(ARRAY[#{ids.join(',')}], #{id_attribute.relation.name}.#{id_attribute.name})"))
    end
  end
end
