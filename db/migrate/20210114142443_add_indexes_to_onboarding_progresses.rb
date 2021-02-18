# frozen_string_literal: true

class AddIndexesToOnboardingProgresses < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CREATE_TRACK_INDEX_NAME = 'index_onboarding_progresses_for_create_track'
  VERIFY_TRACK_INDEX_NAME = 'index_onboarding_progresses_for_verify_track'
  TRIAL_TRACK_INDEX_NAME = 'index_onboarding_progresses_for_trial_track'
  TEAM_TRACK_INDEX_NAME = 'index_onboarding_progresses_for_team_track'

  disable_ddl_transaction!

  def up
    add_concurrent_index :onboarding_progresses, :created_at, where: 'git_write_at IS NULL', name: CREATE_TRACK_INDEX_NAME
    add_concurrent_index :onboarding_progresses, :git_write_at, where: 'git_write_at IS NOT NULL AND pipeline_created_at IS NULL', name: VERIFY_TRACK_INDEX_NAME
    add_concurrent_index :onboarding_progresses, 'GREATEST(git_write_at, pipeline_created_at)', where: 'git_write_at IS NOT NULL AND pipeline_created_at IS NOT NULL AND trial_started_at IS NULL', name: TRIAL_TRACK_INDEX_NAME
    add_concurrent_index :onboarding_progresses, 'GREATEST(git_write_at, pipeline_created_at, trial_started_at)', where: 'git_write_at IS NOT NULL AND pipeline_created_at IS NOT NULL AND trial_started_at IS NOT NULL AND user_added_at IS NULL', name: TEAM_TRACK_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :onboarding_progresses, CREATE_TRACK_INDEX_NAME
    remove_concurrent_index_by_name :onboarding_progresses, VERIFY_TRACK_INDEX_NAME
    remove_concurrent_index_by_name :onboarding_progresses, TRIAL_TRACK_INDEX_NAME
    remove_concurrent_index_by_name :onboarding_progresses, TEAM_TRACK_INDEX_NAME
  end
end
