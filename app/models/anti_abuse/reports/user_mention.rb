# frozen_string_literal: true

module AntiAbuse
  module Reports
    class UserMention < UserMention
      self.table_name = 'abuse_report_user_mentions'

      belongs_to :abuse_report, optional: false
      belongs_to :note, optional: false
    end
  end
end
