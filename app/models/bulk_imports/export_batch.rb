# frozen_string_literal: true

module BulkImports
  class ExportBatch < ApplicationRecord
    self.table_name = 'bulk_import_export_batches'

    BATCH_SIZE = 1000

    belongs_to :export, class_name: 'BulkImports::Export'
    has_one :upload, class_name: 'BulkImports::ExportUpload', foreign_key: :batch_id, inverse_of: :batch

    validates :batch_number, presence: true, uniqueness: { scope: :export_id }

    state_machine :status, initial: :started do
      state :started, value: 0
      state :finished, value: 1
      state :failed, value: -1

      event :start do
        transition any => :started
      end

      event :finish do
        transition started: :finished
        transition failed: :failed
      end

      event :fail_op do
        transition any => :failed
      end
    end
  end
end
