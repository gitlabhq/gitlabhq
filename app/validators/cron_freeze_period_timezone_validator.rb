# frozen_string_literal: true

# CronTimezoneValidator
#
# Custom validator for CronTimezone.
class CronFreezePeriodTimezoneValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    freeze_start_parser = Gitlab::Ci::CronParser.new(record.freeze_start, record.cron_timezone)
    freeze_end_parser = Gitlab::Ci::CronParser.new(record.freeze_end, record.cron_timezone)

    record.errors.add(attribute, 'syntax is invalid') unless freeze_start_parser.cron_timezone_valid? && freeze_end_parser.cron_timezone_valid?
  end
end
