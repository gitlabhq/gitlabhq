# frozen_string_literal: true

class AddAutoCanceledByPartitionIdToPCiBuilds < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  enable_lock_retries!

  def change
    return unless can_execute_on?(:ci_builds)

    add_column :p_ci_builds, :auto_canceled_by_partition_id, :bigint, default: 100, null: false, if_not_exists: true
  end
end
