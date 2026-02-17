# frozen_string_literal: true

class AddCurrentFromAndCurrentUntilToCiPartitions < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :ci_partitions, :current_from, :datetime_with_timezone
    add_column :ci_partitions, :current_until, :datetime_with_timezone
  end
end
