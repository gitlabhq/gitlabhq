# frozen_string_literal: true

module WorkItems
  class DatesSource < ApplicationRecord
    include FromUnion

    self.table_name = 'work_item_dates_sources'

    # namespace is required as the sharding key
    belongs_to :namespace, inverse_of: :work_items_dates_source
    belongs_to :work_item, foreign_key: 'issue_id', inverse_of: :dates_source

    belongs_to :due_date_sourcing_work_item, class_name: 'WorkItem'
    belongs_to :start_date_sourcing_work_item, class_name: 'WorkItem'

    belongs_to :due_date_sourcing_milestone, class_name: 'Milestone'
    belongs_to :start_date_sourcing_milestone, class_name: 'Milestone'

    before_validation :set_namespace
    before_save :set_fixed_start_date, if: :start_date_is_fixed?
    before_save :set_fixed_due_date, if: :due_date_is_fixed?

    scope :work_items_in, ->(work_items) { where(work_item: work_items) }

    private

    def set_namespace
      return if work_item.blank?
      return if work_item.namespace == namespace

      self.namespace = work_item.namespace
    end

    def set_fixed_start_date
      self.start_date = start_date_fixed
    end

    def set_fixed_due_date
      self.due_date = due_date_fixed
    end
  end
end
