# frozen_string_literal: true

class AddStateColumnsToOrganizationDetails < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    add_column :organization_details, :deletion_scheduled_at, :datetime_with_timezone, if_not_exists: true
    add_column :organization_details, :state_metadata, :jsonb, null: false, default: {}, if_not_exists: true
  end

  def down
    remove_column :organization_details, :deletion_scheduled_at, if_exists: true
    remove_column :organization_details, :state_metadata, if_exists: true
  end
end
