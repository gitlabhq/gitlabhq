# frozen_string_literal: true

class AddDefaultValueToMaxHoursBeforeTerminationColumn < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    # NOTE: see the following issue for the reasoning behind this value being the hard maximum termination limit:
    #      https://gitlab.com/gitlab-org/gitlab/-/issues/471994
    change_column_default :workspaces, :max_hours_before_termination, from: nil, to: 8760
  end
end
