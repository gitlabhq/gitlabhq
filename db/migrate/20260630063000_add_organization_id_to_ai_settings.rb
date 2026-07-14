# frozen_string_literal: true

class AddOrganizationIdToAiSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :ai_settings, :organization_id, :bigint
  end
end
