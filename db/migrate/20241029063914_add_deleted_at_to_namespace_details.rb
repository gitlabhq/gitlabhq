# frozen_string_literal: true

class AddDeletedAtToNamespaceDetails < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :namespace_details, :deleted_at, :datetime_with_timezone
  end
end
