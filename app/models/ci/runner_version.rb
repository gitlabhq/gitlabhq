# frozen_string_literal: true

module Ci
  class RunnerVersion < Ci::ApplicationRecord
    include EnumWithNil

    enum_with_nil status: {
      not_processed: nil,
      invalid_version: -1,
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

    validates :version, length: { maximum: 2048 }
  end
end
