# frozen_string_literal: true

class AddLastEnforcedAtToNamespaceLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column :namespace_limits, :last_enforced_at, :datetime_with_timezone
  end
end
