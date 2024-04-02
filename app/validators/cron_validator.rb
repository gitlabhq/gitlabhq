# frozen_string_literal: true

class CronValidator < ActiveModel::EachValidator
  ATTRIBUTE_ALLOWLIST = %i[cron freeze_start freeze_end].freeze

  NonAllowlistedAttributeError = Class.new(StandardError)

  def validate_each(record, attribute, value)
    if ATTRIBUTE_ALLOWLIST.include?(attribute)
      cron_parser = Gitlab::Ci::CronParser.new(record.public_send(attribute), record.cron_timezone) # rubocop:disable GitlabSecurity/PublicSend
      record.errors.add(attribute, 'syntax is invalid') unless cron_parser.cron_valid?
    else
      raise NonAllowlistedAttributeError, "Non-allowlisted attribute"
    end
  end
end
