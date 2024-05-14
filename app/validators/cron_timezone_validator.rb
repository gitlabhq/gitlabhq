# frozen_string_literal: true

# CronTimezoneValidator
#
# Custom validator for CronTimezone.
class CronTimezoneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    cron_parser = Gitlab::Ci::CronParser.new(record.cron, record.cron_timezone)
    record.errors.add(attribute, 'syntax is invalid') unless cron_parser.cron_timezone_valid?
  end
end
