# frozen_string_literal: true

class ValidateClusterProvidersAwsShardingKeyConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  # no-op: this migration was ordered before the finalize migration, causing
  # failures on GDK and self-managed instances that run all migrations at once.
  # Moved to 20260423132624_validate_cluster_providers_aws_sharding_key_constraint_fixed.rb
  def up
    # no-op
  end

  def down
    # no-op
  end
end
