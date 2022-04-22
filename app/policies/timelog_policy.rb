# frozen_string_literal: true

class TimelogPolicy < BasePolicy
  delegate { @subject.issuable }

  desc "User who created the timelog"
  condition(:is_author) { @user && @subject.user == @user }

  rule { is_author | can?(:maintainer_access) }.policy do
    enable :admin_timelog
  end
end
