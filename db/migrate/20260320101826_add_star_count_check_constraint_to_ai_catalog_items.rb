# frozen_string_literal: true

class AddStarCountCheckConstraintToAiCatalogItems < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  CONSTRAINT_NAME = 'check_ai_catalog_items_star_count_non_negative'

  def up
    add_check_constraint :ai_catalog_items, 'star_count >= 0', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :ai_catalog_items, CONSTRAINT_NAME
  end
end
