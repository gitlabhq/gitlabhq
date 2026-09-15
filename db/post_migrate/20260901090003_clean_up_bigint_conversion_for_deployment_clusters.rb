# frozen_string_literal: true

class CleanUpBigintConversionForDeploymentClusters < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '19.4'

  TABLE = :deployment_clusters
  COLUMNS = %i[deployment_id cluster_id].freeze

  def up
    return unless can_execute_on?(TABLE)

    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    # no-op
    #
    # Restoring the shadow columns and sync trigger reactivates the historical
    # conversion chain, whose earlier steps have empty `down` methods, so a
    # rollback past this point fails on objects they never restore.
  end
end
