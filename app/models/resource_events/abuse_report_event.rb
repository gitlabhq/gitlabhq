# frozen_string_literal: true

module ResourceEvents
  class AbuseReportEvent < ApplicationRecord
    include AbuseReportEventsHelper

    belongs_to :abuse_report, optional: false
    belongs_to :user

    validates :action, presence: true

    enum action: {
      ban_user: 1,
      block_user: 2,
      delete_user: 3,
      close_report: 4,
      ban_user_and_close_report: 5,
      block_user_and_close_report: 6,
      delete_user_and_close_report: 7,
      trust_user: 8,
      trust_user_and_close_report: 9
    }

    enum reason: {
      spam: 1,
      offensive: 2,
      phishing: 3,
      crypto: 4,
      credentials: 5,
      copyright: 6,
      malware: 7,
      other: 8,
      unconfirmed: 9,
      trusted: 10
    }

    def success_message
      success_message_for_action(action)
    end
  end
end
