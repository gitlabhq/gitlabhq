# frozen_string_literal: true

class CronValidator < ActiveModel::EachValidator
  ATTRIBUTE_WHITELIST = %i[cron freeze_start freeze_end].freeze

  NonWhitelistedAttributeError = Class.new(StandardError)

  def validate_each(record, attribute, value)
    if ATTRIBUTE_WHITELIST.include?(attribute)
      cron_parser = Gitlab::Ci::CronParser.new(record.public_send(attribute), record.cron_timezone) # rubocop:disable GitlabSecurity/PublicSend
      record.errors.add(attribute, " is invalid syntax") unless cron_parser.cron_valid?
    else
      raise NonWhitelistedAttributeError, "Non-whitelisted attribute"
    end
  end
end
