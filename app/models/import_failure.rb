# frozen_string_literal: true

class ImportFailure < ApplicationRecord
  belongs_to :project
  belongs_to :group

  validates :project, presence: true, unless: :group
  validates :group, presence: true, unless: :project

  # Returns any `import_failures` for relations that were unrecoverable errors or failed after
  # several retries. An import can be successful even if some relations failed to import correctly.
  # A retry_count of 0 indicates that either no retries were attempted, or they were exceeded.
  scope :hard_failures_by_correlation_id, ->(correlation_id) {
    where(correlation_id_value: correlation_id, retry_count: 0).order(created_at: :desc)
  }
end
