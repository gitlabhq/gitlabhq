# frozen_string_literal: true

class SetApiRateLimitsToZero < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting

  milestone '18.0'

  def up
    # no-op: As of milestone 18.3, we no longer want to set rate limits to zero for new SM installations
    # so they receive the proper rate limits instead.
  end

  def down
    # no-op
  end
end
