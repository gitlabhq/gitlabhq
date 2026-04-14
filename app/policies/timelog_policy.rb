# frozen_string_literal: true

class TimelogPolicy < BasePolicy
  delegate { @subject.issuable }

  desc "User who created the timelog"
  condition(:is_author) { @user && @subject.user == @user }

  rule { is_author & can?(:_delete_authored_timelog) }.policy do
    enable :delete_timelog

    # TODO: Remove admin_timelog once the GraphQL TimelogPermissions type
    # is updated to expose delete_timelog instead. Kept for now to avoid
    # a breaking change in the GraphQL schema (adminTimelog field).
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/565573
    enable :admin_timelog
  end

  rule { can?(:admin_timelog) }.policy do
    enable :delete_timelog
  end
end
