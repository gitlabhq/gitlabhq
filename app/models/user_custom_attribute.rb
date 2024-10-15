# frozen_string_literal: true

class UserCustomAttribute < ApplicationRecord
  belongs_to :user

  validates :user_id, :key, :value, presence: true
  validates :key, uniqueness: { scope: [:user_id] }

  scope :by_key, ->(key) { where(key: key) }
  scope :by_user_id, ->(user_id) { where(user_id: user_id) }
  scope :by_updated_at, ->(updated_at) { where(updated_at: updated_at) }
  scope :arkose_sessions, -> { by_key(ARKOSE_SESSION) }
  scope :trusted_with_spam, -> { by_key(TRUSTED_BY) }

  BLOCKED_BY = 'blocked_by'
  UNBLOCKED_BY = 'unblocked_by'
  ARKOSE_RISK_BAND = 'arkose_risk_band'
  ARKOSE_SESSION = 'arkose_session'
  AUTO_BANNED_BY_ABUSE_REPORT_ID = 'auto_banned_by_abuse_report_id'
  AUTO_BANNED_BY_SPAM_LOG_ID = 'auto_banned_by_spam_log_id'
  TRUSTED_BY = 'trusted_by'
  AUTO_BANNED_BY = 'auto_banned_by'
  IDENTITY_VERIFICATION_PHONE_EXEMPT = 'identity_verification_phone_exempt'
  IDENTITY_VERIFICATION_EXEMPT = 'identity_verification_exempt'
  DELETED_OWN_ACCOUNT_AT = 'deleted_own_account_at'
  SKIPPED_ACCOUNT_DELETION_AT = 'skipped_account_deletion_at'
  DEEP_CLEAN_CI_USAGE_WHEN_BANNED = 'deep_clean_ci_usage_when_banned'

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

      upsert_custom_attribute(
        user_id: abuse_report.user.id,
        key: AUTO_BANNED_BY_ABUSE_REPORT_ID,
        value: abuse_report.id
      )
    end

    def set_banned_by_spam_log(spam_log)
      return unless spam_log

      upsert_custom_attribute(user_id: spam_log.user_id, key: AUTO_BANNED_BY_SPAM_LOG_ID, value: spam_log.id)
    end

    def set_auto_banned_by(user:, reason:)
      upsert_custom_attribute(user_id: user.id, key: AUTO_BANNED_BY, value: reason)
    end

    def set_trusted_by(user:, trusted_by:)
      return unless user && trusted_by

      upsert_custom_attribute(
        user_id: user.id,
        key: UserCustomAttribute::TRUSTED_BY,
        value: "#{trusted_by.username}/#{trusted_by.id}+#{Time.current}"
      )
    end

    def set_deleted_own_account_at(user)
      return unless user

      upsert_custom_attribute(user_id: user.id, key: DELETED_OWN_ACCOUNT_AT, value: Time.zone.now.to_s)
    end

    def set_skipped_account_deletion_at(user)
      return unless user

      upsert_custom_attribute(user_id: user.id, key: SKIPPED_ACCOUNT_DELETION_AT, value: Time.zone.now.to_s)
    end

    def upsert_custom_attribute(user_id:, key:, value:)
      return unless user_id && key && value

      custom_attribute = {
        user_id: user_id,
        key: key,
        value: value
      }

      upsert_custom_attributes([custom_attribute])
    end

    private

    def blocked_users
      by_key('blocked_at').by_updated_at(Date.yesterday.all_day)
    end
  end
end
