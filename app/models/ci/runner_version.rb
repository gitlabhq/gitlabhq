# frozen_string_literal: true

module Ci
  class RunnerVersion < Ci::ApplicationRecord
    include EachBatch

    enum status: {
      not_processed: nil,
      invalid_version: -1,
      unavailable: 1,
      available: 2,
      recommended: 3
    }

    STATUS_DESCRIPTIONS = {
      invalid_version: 'Runner version is not valid.',
      unavailable: 'Upgrade is not available for the runner.',
      available: 'Upgrade is available for the runner.',
      recommended: 'Upgrade is available and recommended for the runner.'
    }.freeze

    has_many :runner_managers, inverse_of: :runner_version, foreign_key: :version, class_name: 'Ci::RunnerManager'

    # This scope returns all versions that might need recalculating. For instance, once a version is considered
    # :recommended, it normally doesn't change status even if the instance is upgraded
    scope :potentially_outdated, -> { where(status: [nil, :unavailable, :available]) }

    validates :version, length: { maximum: 2048 }
  end
end
