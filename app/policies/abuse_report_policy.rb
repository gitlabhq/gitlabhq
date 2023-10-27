# frozen_string_literal: true

class AbuseReportPolicy < ::BasePolicy
  rule { admin }.policy do
    enable :read_abuse_report
    enable :create_note
  end
end
