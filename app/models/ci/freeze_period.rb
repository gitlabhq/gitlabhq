# frozen_string_literal: true

module Ci
  class FreezePeriod < ApplicationRecord
    include StripAttribute
    self.table_name = 'ci_freeze_periods'

    default_scope { order(created_at: :asc) }

    belongs_to :project, inverse_of: :freeze_periods

    strip_attributes :freeze_start, :freeze_end

    validates :freeze_start, cron: true, presence: true
    validates :freeze_end, cron: true, presence: true
    validates :cron_timezone, cron_freeze_period_timezone: true, presence: true
  end
end
