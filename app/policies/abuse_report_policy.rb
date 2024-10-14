# frozen_string_literal: true

class AbuseReportPolicy < ::BasePolicy
  rule { admin }.policy do
    enable :read_abuse_report
    enable :read_note
    enable :create_note
    enable :update_note
  end
end
