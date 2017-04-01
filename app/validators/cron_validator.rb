# CronValidator
#
# Custom validator for Cron.
class CronValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    cron_parser = Ci::CronParser.new(record.cron, record.cron_time_zone)
    is_valid_cron, is_valid_cron_time_zone = cron_parser.validation

    if !is_valid_cron
      record.errors.add(:cron, " is invalid syntax")
    elsif !is_valid_cron_time_zone
      record.errors.add(:cron_time_zone, " is invalid timezone")
    end
  end
end
