# frozen_string_literal: true

module ResourceEvents
  class AbuseReportEvent < ApplicationRecord
    belongs_to :abuse_report, optional: false
    belongs_to :user

    validates :action, presence: true

    enum action: {
      ban_user: 1,
      block_user: 2,
      delete_user: 3,
      close_report: 4
    }

    enum reason: {
      spam: 1,
      offensive: 2,
      phishing: 3,
      crypto: 4,
      credentials: 5,
      copyright: 6,
      malware: 7,
      other: 8
    }
  end
end
