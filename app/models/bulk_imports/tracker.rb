# frozen_string_literal: true

class BulkImports::Tracker < ApplicationRecord
  self.table_name = 'bulk_import_trackers'

  belongs_to :entity,
    class_name: 'BulkImports::Entity',
    foreign_key: :bulk_import_entity_id,
    optional: false

  validates :relation,
    presence: true,
    uniqueness: { scope: :bulk_import_entity_id }

  validates :next_page, presence: { if: :has_next_page? }

  validates :stage, presence: true

  state_machine :status, initial: :created do
    state :created, value: 0
    state :started, value: 1
    state :finished, value: 2
    state :failed, value: -1
    state :skipped, value: -2

    event :start do
      transition created: :started
    end

    event :finish do
      transition started: :finished
      transition failed: :failed
      transition skipped: :skipped
    end

    event :skip do
      transition any => :skipped
    end

    event :fail_op do
      transition any => :failed
    end
  end
end
