# frozen_string_literal: true

module WorkItems
  class Position < ApplicationRecord
    self.table_name = 'work_item_positions'

    belongs_to :work_item, class_name: 'WorkItem', inverse_of: :work_item_position
    belongs_to :namespace

    validates :namespace, :work_item, presence: true

    before_validation :copy_namespace_from_work_item

    private

    def copy_namespace_from_work_item
      self.namespace = work_item&.namespace
    end
  end
end
