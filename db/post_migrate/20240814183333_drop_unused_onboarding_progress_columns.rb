# frozen_string_literal: true

class DropUnusedOnboardingProgressColumns < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE = :onboarding_progresses

  UNUSED_COLUMNS = %i[
    git_pull_at
    subscription_created_at
    scoped_label_created_at
    security_scan_enabled_at
    issue_auto_closed_at
    repository_imported_at
    repository_mirrored_at
    secure_container_scanning_run_at
    secure_secret_detection_run_at
    secure_coverage_fuzzing_run_at
    secure_cluster_image_scanning_run_at
    secure_api_fuzzing_run_at
  ]

  def up
    UNUSED_COLUMNS.each do |column|
      remove_column TABLE, column, if_exists: true
    end
  end

  def down
    UNUSED_COLUMNS.each do |column|
      add_column TABLE, column, :timestamptz, if_not_exists: true
    end
  end
end
