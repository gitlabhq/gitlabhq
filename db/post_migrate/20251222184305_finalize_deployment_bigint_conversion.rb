# frozen_string_literal: true

class FinalizeDeploymentBigintConversion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.8'

  COLUMNS = %i[id environment_id project_id user_id].freeze

  def up
    ensure_backfill_conversion_of_integer_to_bigint_is_finished(
      'deployments',
      COLUMNS
    )
  end

  def down; end
end
