# frozen_string_literal: true

module SortableTitle
  extend ActiveSupport::Concern

  included do
    scope :order_title_asc, -> { reorder(Arel::Nodes::Ascending.new(arel_table[:title].lower)) }
    scope :order_title_desc, -> { reorder(Arel::Nodes::Descending.new(arel_table[:title].lower)) }
  end

  class_methods do
    def simple_sorts
      super.merge(
        {
          'title_asc' => -> { order_title_asc },
          'title_desc' => -> { order_title_desc }
        }
      )
    end
  end
end
