# frozen_string_literal: true

class AddAutoCanceledByPartitionIdToPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    # no-op
    # moved to db/migrate/20231020074227_add_auto_canceled_by_partition_id_to_p_ci_builds_self_managed.rb
  end

  def down
    # no-op
    # moved to db/migrate/20231020074227_add_auto_canceled_by_partition_id_to_p_ci_builds_self_managed.rb
  end
end
