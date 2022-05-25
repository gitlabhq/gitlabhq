# frozen_string_literal: true

module WorkItems
  class ParentLink < ApplicationRecord
    self.table_name = 'work_item_parent_links'

    belongs_to :work_item
    belongs_to :work_item_parent, class_name: 'WorkItem'
  end
end
