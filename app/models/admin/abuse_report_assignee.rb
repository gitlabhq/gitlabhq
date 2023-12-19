# frozen_string_literal: true

module Admin
  class AbuseReportAssignee < ApplicationRecord
    self.table_name = 'abuse_report_assignees'

    belongs_to :abuse_report, touch: true
    belongs_to :assignee, class_name: "User", foreign_key: :user_id, inverse_of: :admin_abuse_report_assignees

    validates :assignee, uniqueness: { scope: :abuse_report_id }
  end
end
