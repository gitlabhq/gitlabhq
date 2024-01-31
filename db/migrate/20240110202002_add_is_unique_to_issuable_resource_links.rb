# frozen_string_literal: true

class AddIsUniqueToIssuableResourceLinks < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def change
    add_column :issuable_resource_links, :is_unique, :boolean, null: true
  end
end
