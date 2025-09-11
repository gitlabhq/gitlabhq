# frozen_string_literal: true

module AntiAbuse
  module Reports
    class UserMention < UserMention
      self.table_name = 'abuse_report_user_mentions'

      belongs_to :abuse_report, class_name: '::AbuseReport', optional: false
      belongs_to :note, optional: false
      belongs_to :organization, class_name: 'Organizations::Organization'

      validates :organization_id, presence: true, if: -> {
        Feature.enabled?(:abuse_report_populate_organization, :instance)
      }
    end
  end
end
