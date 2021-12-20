# frozen_string_literal: true

class ScheduleDeleteInvalidEpicIssues < Gitlab::Database::Migration[1.0]
  # This is a now a no-op
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/348477

  def up
    # no-op
  end

  def down
    # also no-op
  end
end
