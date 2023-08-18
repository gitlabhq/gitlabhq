# frozen_string_literal: true

module Admin
  class AbuseReportLabelPolicy < ::BasePolicy
    rule { admin }.policy do
      enable :read_label
    end
  end
end
