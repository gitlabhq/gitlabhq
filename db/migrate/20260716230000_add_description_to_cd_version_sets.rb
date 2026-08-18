# frozen_string_literal: true

class AddDescriptionToCdVersionSets < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  def up
    add_column :cd_version_sets, :description, :text, if_not_exists: true

    add_text_limit :cd_version_sets, :description, 2000
  end

  def down
    remove_column :cd_version_sets, :description, if_exists: true
  end
end
