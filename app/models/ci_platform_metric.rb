# frozen_string_literal: true

class CiPlatformMetric < ApplicationRecord
  include BulkInsertSafe

  PLATFORM_TARGET_MAX_LENGTH = 255

  validates :recorded_at, presence: true
  validates :platform_target,
    exclusion: [nil], # allow '' (the empty string), but not nil
    length: { maximum: PLATFORM_TARGET_MAX_LENGTH }
  validates :count,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 }

  CI_VARIABLE_KEY = 'AUTO_DEVOPS_PLATFORM_TARGET'

  def self.insert_auto_devops_platform_targets!
    # This work can NOT be done in-database because value is encrypted.
    # However, for 'AUTO_DEVOPS_PLATFORM_TARGET', these values are only
    # encrypted as a matter of course, rather than as a need for secrecy.
    # So this is not a security risk, but exposing other keys possibly could be.
    variables = Ci::Variable.by_key(CI_VARIABLE_KEY)
    recorded_at = Time.zone.now
    counts = variables.group_by(&:value).map do |value, variables|
      target = value.truncate(PLATFORM_TARGET_MAX_LENGTH, separator: '', omission: '')
      count = variables.count
      self.new(recorded_at: recorded_at, platform_target: target, count: count)
    end

    bulk_insert!(counts, validate: true)
  end
end
