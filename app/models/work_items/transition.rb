# frozen_string_literal: true

module WorkItems
  class Transition < ApplicationRecord
    self.primary_key = :work_item_id
    self.table_name = 'work_item_transitions'

    belongs_to :work_item, class_name: 'WorkItem', inverse_of: :work_item_transition
    belongs_to :namespace
    belongs_to :duplicated_to, class_name: 'WorkItem', optional: true
    belongs_to :moved_to, class_name: 'WorkItem', optional: true

    validates :namespace, presence: true

    before_validation :set_namespace

    def set_namespace
      return if work_item.nil?
      return if work_item.namespace == namespace

      self.namespace = work_item.namespace
    end
  end
end

WorkItems::Transition.prepend_mod
