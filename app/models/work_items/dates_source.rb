# frozen_string_literal: true

module WorkItems
  class DatesSource < ApplicationRecord
    include FromUnion

    # ElasticSearch is limited to use dates within this range
    MAX_DATE_LIMIT = Date.new(9999, 12, 31).freeze
    MIN_DATE_LIMIT = Date.new(1000, 1, 1).freeze

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

    with_options(comparison: {
      allow_nil: true,
      less_than_or_equal_to: MAX_DATE_LIMIT,
      greater_than_or_equal_to: MIN_DATE_LIMIT
    }, if: :validate_dates?) do
      validates :start_date
      validates :start_date_fixed
      validates :due_date
      validates :due_date_fixed
    end

    private

    # Validate for new records or when any date field has changed
    def validate_dates?
      new_record? || any_dates_changed?
    end

    def any_dates_changed?
      (changed_attributes.keys & %w[start_date start_date_fixed due_date due_date_fixed])
        .present?
    end

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
