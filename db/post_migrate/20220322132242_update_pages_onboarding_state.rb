# frozen_string_literal: true

class UpdatePagesOnboardingState < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!
  BATCH_SIZE = 75

  def up
    define_batchable_model(
      :project_pages_metadata
    ).where(
      deployed: true
    ).each_batch(
      of: BATCH_SIZE,
      column: :project_id
    ) do |batch|
      batch.update_all(onboarding_complete: true)
    end
  end

  def down
    define_batchable_model(
      :project_pages_metadata
    ).where(
      onboarding_complete: true
    ).each_batch(
      of: BATCH_SIZE,
      column: :project_id
    ) do |batch|
      batch.update_all(onboarding_complete: false)
    end
  end
end
