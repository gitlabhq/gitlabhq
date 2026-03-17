# frozen_string_literal: true

class DropNamespaceDetailsDeletedAtColumn < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    remove_column :namespace_details, :deleted_at
  end

  def down
    add_column :namespace_details, :deleted_at, :datetime_with_timezone
  end
end
