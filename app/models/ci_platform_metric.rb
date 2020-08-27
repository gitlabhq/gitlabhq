# frozen_string_literal: true

class CiPlatformMetric < ApplicationRecord
  validates :recorded_at, presence: true
  validates :platform_target, presence: true, length: { maximum: 255 }
  validates :count, presence: true

  CI_VARIABLE_KEY = "AUTO_DEVOPS_PLATFORM_TARGET"

  def self.update!
    # This work can NOT be done in-database because value is encrypted.
    # However, for "AUTO_DEVOPS_PLATFORM_TARGET", these values are only
    # encrypted as a matter of course, rather than as a need for secrecy.
    # So this is not a security risk, but exposing other keys possibly could be.
    variables = Ci::Variable.by_key(CI_VARIABLE_KEY)
    update_recorded_at = Time.zone.now
    counts = variables.group_by(&:value).map do |value, variables|
      {
        recorded_at: update_recorded_at,
        platform_target: value,
        count: variables.count
      }
    end

    create(counts)
  end
end
