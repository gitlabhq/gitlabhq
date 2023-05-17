# frozen_string_literal: true

class ScheduleFkValidationForPCiBuildsMetadataPartitionsAndCiBuilds < Gitlab::Database::Migration[2.1]
  # This migration was used to validate the foreign keys on partitions introduced by
  # db/post_migrate/20230221125148_add_fk_to_p_ci_builds_metadata_partitions_on_partition_id_and_build_id.rb
  # but executing the rollback of
  # db/post_migrate/20230306072532_add_partitioned_fk_to_p_ci_builds_metadata_on_partition_id_and_build_id.rb
  # would also remove the FKs on partitions and this would errors out.

  def up
    # No-op
  end

  def down
    # No-op
  end
end
