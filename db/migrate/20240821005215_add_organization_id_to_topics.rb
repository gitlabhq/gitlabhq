# frozen_string_literal: true

class AddOrganizationIdToTopics < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  DEFAULT_ORGANIZATION_ID = 1

  def change
    add_column :topics, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: false
  end
end
