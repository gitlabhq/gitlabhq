# frozen_string_literal: true

class UserCustomAttribute < ApplicationRecord
  belongs_to :user

  validates :user_id, :key, :value, presence: true
  validates :key, uniqueness: { scope: [:user_id] }

  scope :by_key, ->(key) { where(key: key) }
  scope :by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :by_updated_at, ->(updated_at) { where(updated_at: updated_at) }
  scope :arkose_sessions, -> { by_key('arkose_session') }

  BLOCKED_BY = 'blocked_by'
  UNBLOCKED_BY = 'unblocked_by'
  ARKOSE_RISK_BAND = 'arkose_risk_band'
  AUTO_BANNED_BY_ABUSE_REPORT_ID = 'auto_banned_by_abuse_report_id'
  ALLOW_POSSIBLE_SPAM = 'allow_possible_spam'
  IDENTITY_VERIFICATION_PHONE_EXEMPT = 'identity_verification_phone_exempt'

  class << self
    def upsert_custom_attributes(custom_attributes)
      created_at = DateTime.now
      updated_at = DateTime.now

      custom_attributes.map! do |custom_attribute|
        custom_attribute.merge({ created_at: created_at, updated_at: updated_at })
      end
      upsert_all(custom_attributes, unique_by: [:user_id, :key])
    end

    def sessions
      return none if blocked_users.empty?

      arkose_sessions
        .by_user_id(blocked_users.map(&:user_id))
        .select(:value)
    end

    def set_banned_by_abuse_report(abuse_report)
      return unless abuse_report

      custom_attribute = { user_id: abuse_report.user.id, key: AUTO_BANNED_BY_ABUSE_REPORT_ID, value: abuse_report.id }

      upsert_custom_attributes([custom_attribute])
    end

    private

    def blocked_users
      by_key('blocked_at').by_updated_at(Date.yesterday.all_day)
    end
  end
end
