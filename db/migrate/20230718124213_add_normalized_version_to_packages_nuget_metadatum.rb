# frozen_string_literal: true

class AddNormalizedVersionToPackagesNugetMetadatum < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :packages_nuget_metadata, :normalized_version, :text, if_not_exists: true
    end

    add_text_limit :packages_nuget_metadata, :normalized_version, 255
  end

  def down
    with_lock_retries do
      remove_column :packages_nuget_metadata, :normalized_version, if_exists: true
    end
  end
end
