# frozen_string_literal: true

module Ci
  class RunnerVersion < Ci::ApplicationRecord
    include EachBatch
    include EnumWithNil
    include BulkInsertSafe # include this last (see https://docs.gitlab.com/ee/development/insert_into_tables_in_batches.html#prepare-applicationrecords-for-bulk-insertion)

    enum_with_nil status: {
      not_processed: nil,
      invalid_version: -1, # Named invalid_version to avoid clash with auto-generated `invalid?` ActiveRecord method
      unknown: 0,
      not_available: 1,
      available: 2,
      recommended: 3
    }

    STATUS_DESCRIPTIONS = {
      invalid_version: 'Runner version is not valid.',
      unknown: 'Upgrade status is unknown.',
      not_available: 'Upgrade is not available for the runner.',
      available: 'Upgrade is available for the runner.',
      recommended: 'Upgrade is available and recommended for the runner.'
    }.freeze

    # Override auto generated negative scope (from available) so the scope has expected behavior
    scope :not_available, -> { where(status: :not_available) }

    # This scope returns all versions that might need recalculating. For instance, once a version is considered
    # :recommended, it normally doesn't change status even if the instance is upgraded
    scope :potentially_outdated, -> { where(status: [nil, :not_available, :available, :unknown]) }

    validates :version, length: { maximum: 2048 }
  end
end
