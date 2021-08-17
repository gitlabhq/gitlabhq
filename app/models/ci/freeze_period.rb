# frozen_string_literal: true

module Ci
  class FreezePeriod < Ci::ApplicationRecord
    include StripAttribute
    include Ci::NamespacedModelName

    default_scope { order(created_at: :asc) } # rubocop:disable Cop/DefaultScope

    belongs_to :project, inverse_of: :freeze_periods

    strip_attributes! :freeze_start, :freeze_end

    validates :freeze_start, cron: true, presence: true
    validates :freeze_end, cron: true, presence: true
    validates :cron_timezone, cron_freeze_period_timezone: true, presence: true
  end
end
