# frozen_string_literal: true

class RemoveOnboardingProgressesGitWriteAtColumn < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  TABLE_NAME = :onboarding_progresses
  COLUMN_NAME = :git_write_at
  CREATE_INDEX = :index_onboarding_progresses_for_create_track
  TEAM_INDEX = :index_onboarding_progresses_for_team_track
  TRIAL_INDEX = :index_onboarding_progresses_for_trial_track
  VERIFY_INDEX = :index_onboarding_progresses_for_verify_track

  def up
    remove_concurrent_index_by_name(TABLE_NAME, CREATE_INDEX)
    remove_concurrent_index_by_name(TABLE_NAME, TEAM_INDEX)
    remove_concurrent_index_by_name(TABLE_NAME, TRIAL_INDEX)
    remove_concurrent_index_by_name(TABLE_NAME, VERIFY_INDEX)

    remove_column(TABLE_NAME, COLUMN_NAME)
  end

  def down
    add_column(TABLE_NAME, COLUMN_NAME, :datetime_with_timezone)

    add_concurrent_index(TABLE_NAME, :created_at, where: "#{COLUMN_NAME} IS NULL", name: CREATE_INDEX)

    disable_statement_timeout do
      execute <<~SQL
        CREATE INDEX CONCURRENTLY #{TEAM_INDEX}
        ON #{TABLE_NAME}
        USING btree (GREATEST(#{COLUMN_NAME}, pipeline_created_at, trial_started_at))
        WHERE ((#{COLUMN_NAME} IS NOT NULL)
          AND (pipeline_created_at IS NOT NULL)
          AND (trial_started_at IS NOT NULL)
          AND (user_added_at IS NULL))
      SQL
    end

    disable_statement_timeout do
      execute <<~SQL
        CREATE INDEX CONCURRENTLY #{TRIAL_INDEX}
        ON #{TABLE_NAME}
        USING btree (GREATEST(#{COLUMN_NAME}, pipeline_created_at))
        WHERE ((#{COLUMN_NAME} IS NOT NULL)
          AND (pipeline_created_at IS NOT NULL)
          AND (trial_started_at IS NULL))
      SQL
    end

    add_concurrent_index(
      TABLE_NAME,
      COLUMN_NAME,
      where: "(#{COLUMN_NAME} IS NOT NULL) AND (pipeline_created_at IS NULL)",
      name: VERIFY_INDEX
    )
  end
end
