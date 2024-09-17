# frozen_string_literal: true

class CapWorkspacesMaxTerminationToOneYear < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.4'
  # NOTE: see the following issue for the reasoning behind this value being the hard maximum termination limit:
  #      https://gitlab.com/gitlab-org/gitlab/-/issues/471994
  TERMINATION_LIMIT_IN_HOURS = 8760

  def up
    execute(<<~SQL)
      UPDATE workspaces
      SET max_hours_before_termination = #{TERMINATION_LIMIT_IN_HOURS}
      WHERE max_hours_before_termination > #{TERMINATION_LIMIT_IN_HOURS}
    SQL
  end

  def down
    # no-op
  end
end
