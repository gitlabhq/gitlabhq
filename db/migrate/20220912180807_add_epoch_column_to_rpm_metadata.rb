# frozen_string_literal: true

class AddEpochColumnToRpmMetadata < Gitlab::Database::Migration[2.0]
  def change
    add_column :packages_rpm_metadata, :epoch, :integer, null: false, default: 0
  end
end
