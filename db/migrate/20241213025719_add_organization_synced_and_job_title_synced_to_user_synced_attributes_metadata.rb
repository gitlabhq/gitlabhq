# frozen_string_literal: true

class AddOrganizationSyncedAndJobTitleSyncedToUserSyncedAttributesMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :user_synced_attributes_metadata, :organization_synced, :boolean, default: false
    add_column :user_synced_attributes_metadata, :job_title_synced, :boolean, default: false
  end
end
