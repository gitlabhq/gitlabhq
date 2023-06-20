# frozen_string_literal: true

class AddAuthorsAndDescriptionToNugetMetadatum < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :packages_nuget_metadata, :authors, :text, if_not_exists: true
      add_column :packages_nuget_metadata, :description, :text, if_not_exists: true
    end

    add_text_limit :packages_nuget_metadata, :authors, 255
    add_text_limit :packages_nuget_metadata, :description, 4000
  end

  def down
    with_lock_retries do
      remove_column :packages_nuget_metadata, :authors, if_exists: true
      remove_column :packages_nuget_metadata, :description, if_exists: true
    end
  end
end
