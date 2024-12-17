# frozen_string_literal: true

class RemoveNamespaceLimitsTemporaryStorageIncreaseEndsOnColumn < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    remove_column :namespace_limits, :temporary_storage_increase_ends_on
  end

  def down
    add_column :namespace_limits, :temporary_storage_increase_ends_on, :date
  end
end
