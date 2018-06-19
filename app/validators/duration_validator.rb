# DurationValidator
#
# Validate the format conforms with ChronicDuration
#
# Example:
#
#   class ApplicationSetting < ApplicationRecord
#     validates :default_artifacts_expire_in, presence: true, duration: true
#   end
#
class DurationValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    ChronicDuration.parse(value)
  rescue ChronicDuration::DurationParseError
    record.errors.add(attribute, "is not a correct duration")
  end
end
