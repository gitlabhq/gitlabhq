# frozen_string_literal: true

class CiPlatformMetric < Ci::ApplicationRecord
  include BulkInsertSafe

  self.table_name = 'ci_platform_metrics'

  PLATFORM_TARGET_MAX_LENGTH = 255

  validates :recorded_at, presence: true
  validates :platform_target,
    exclusion: [nil], # allow '' (the empty string), but not nil
    length: { maximum: PLATFORM_TARGET_MAX_LENGTH }
  validates :count,
    presence: true,
    numericality: { only_integer: true, greater_than: 0 }

  CI_VARIABLE_KEY = 'AUTO_DEVOPS_PLATFORM_TARGET'
  ALLOWED_TARGETS = %w[ECS FARGATE EC2].freeze

  def self.insert_auto_devops_platform_targets!
    recorded_at = Time.zone.now

    # This work can NOT be done in-database because value is encrypted.
    # However, for 'AUTO_DEVOPS_PLATFORM_TARGET', these values are only
    # encrypted as a matter of course, rather than as a need for secrecy.
    # So this is not a security risk, but exposing other keys possibly could be.
    variables = Ci::Variable.by_key(CI_VARIABLE_KEY)

    counts = variables.group_by(&:value).map do |value, variables|
      # While this value is, in theory, not secret. A user could accidentally
      # put a secret in here so we need to make sure we filter invalid values.
      next unless ALLOWED_TARGETS.include?(value)

      count = variables.count
      self.new(recorded_at: recorded_at, platform_target: value, count: count)
    end.compact

    bulk_insert!(counts, validate: true)
  end
end
