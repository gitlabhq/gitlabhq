# frozen_string_literal: true

class FeatureFlagUserXidsValidator < ActiveModel::EachValidator
  USERXID_MAX_LENGTH = 256

  def validate_each(record, attribute, value)
    self.class.validate_user_xids(record, attribute, value, attribute)
  end

  class << self
    def validate_user_xids(record, attribute, user_xids, error_message_attribute_name)
      unless user_xids.is_a?(String) && !user_xids.match(/[\n\r\t]|,,/) && valid_xids?(user_xids.split(","))
        record.errors.add(attribute,
          "#{error_message_attribute_name} must be a string of unique comma separated values each #{USERXID_MAX_LENGTH} characters or less")
      end
    end

    private

    def valid_xids?(user_xids)
      user_xids.uniq.length == user_xids.length &&
        user_xids.all? { |xid| valid_xid?(xid) }
    end

    def valid_xid?(user_xid)
      user_xid.present? &&
        user_xid.strip == user_xid &&
        user_xid.length <= USERXID_MAX_LENGTH
    end
  end
end
