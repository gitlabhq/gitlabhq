# frozen_string_literal: true

module WorkItems
  class HierarchyRestriction < ApplicationRecord
    self.table_name = 'work_item_hierarchy_restrictions'

    belongs_to :parent_type, class_name: 'WorkItems::Type'
    belongs_to :child_type, class_name: 'WorkItems::Type'

    validates :parent_type, presence: true
    validates :child_type, presence: true
    validates :child_type, uniqueness: { scope: :parent_type_id }
  end
end
