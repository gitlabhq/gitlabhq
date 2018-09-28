# frozen_string_literal: true

# CronValidator
#
# Custom validator for Cron.
class CronValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    cron_parser = Gitlab::Ci::CronParser.new(record.cron, record.cron_timezone)
    record.errors.add(attribute, " is invalid syntax") unless cron_parser.cron_valid?
  end
end
