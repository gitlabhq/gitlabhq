# frozen_string_literal: true

class AddFileFinalPathToVirtualRegistriesPackagesMavenCachedResponses < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  def up
    with_lock_retries do
      add_column :virtual_registries_packages_maven_cached_responses, :file_final_path, :text, if_not_exists: true
    end

    add_text_limit :virtual_registries_packages_maven_cached_responses, :file_final_path, 1024
  end

  def down
    with_lock_retries do
      remove_column :virtual_registries_packages_maven_cached_responses, :file_final_path, if_exists: true
    end
  end
end
