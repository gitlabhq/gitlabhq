# frozen_string_literal: true

class RescaleGeoVerificationMaxCapacity < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_local

  # Number of verification-enabled Replicator classes in GitLab 19.3. Hardcoded (rather than
  # read from Gitlab::Geo at runtime) so the migration is deterministic and loads no
  # application code. See the MR description for the rationale and the replicator list.
  VERIFICATION_ENABLED_REPLICATOR_COUNT = 18

  def up
    execute(<<~SQL)
      UPDATE geo_nodes
      SET verification_max_capacity = GREATEST(1, verification_max_capacity / #{VERIFICATION_ENABLED_REPLICATOR_COUNT})
    SQL
  end

  def down
    # No-op: the original per-node values cannot be recovered after integer division.
  end
end
