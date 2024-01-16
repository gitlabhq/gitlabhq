# frozen_string_literal: true

module WorkItems
  class HierarchyRestriction < ApplicationRecord
    self.table_name = 'work_item_hierarchy_restrictions'

    belongs_to :parent_type, class_name: 'WorkItems::Type'
    belongs_to :child_type, class_name: 'WorkItems::Type'

    after_destroy :clear_parent_type_cache!
    after_save :clear_parent_type_cache!

    validates :parent_type, presence: true
    validates :child_type, presence: true
    validates :child_type, uniqueness: { scope: :parent_type_id }

    private

    def clear_parent_type_cache!
      parent_type.clear_reactive_cache!
    end
  end
end
