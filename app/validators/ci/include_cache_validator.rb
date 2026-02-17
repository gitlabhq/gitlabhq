# frozen_string_literal: true

module Ci
  # Ci::IncludeCacheValidator
  #
  # Validates cache configuration for CI includes
  #
  # Example:
  #
  #   class MyConfig
  #     validates :cache, 'ci/include_cache': true
  #   end
  #
  class IncludeCacheValidator < ActiveModel::EachValidator
    MIN_DURATION = 60 # seconds (1 minute)

    def validate_each(record, attribute, value)
      return if value.blank?

      validate_remote_include(record, attribute)
      validate_cache_value(record, attribute, value)
    end

    private

    def validate_remote_include(record, attribute)
      return if record.config.is_a?(Hash) && record.config[:remote].present?

      record.errors.add(:config, "#{attribute} can only be specified for remote includes")
    end

    def validate_cache_value(record, attribute, value)
      return if value == true

      unless value.is_a?(String)
        record.errors.add(:config, "#{attribute} must be a boolean or a duration string")
        return
      end

      validate_duration(record, attribute, value)
    end

    def validate_duration(record, attribute, value)
      unless Gitlab::Ci::Build::DurationParser.validate_duration(value)
        record.errors.add(:config, "#{attribute} contains an invalid duration")
        return
      end

      seconds = ChronicDuration.parse(value)

      return unless seconds < MIN_DURATION

      min_humanized = ChronicDuration.output(MIN_DURATION, format: :long)
      record.errors.add(:config, "#{attribute} duration must be at least #{min_humanized}")
    end
  end
end
