# frozen_string_literal: true

class AddFileDigestsToVirtualRegistriesMavenCachedResponses < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def up
    truncate_tables!('virtual_registries_packages_maven_cached_responses')

    with_lock_retries do
      add_column :virtual_registries_packages_maven_cached_responses, :file_md5, :binary, if_not_exists: true
      add_column :virtual_registries_packages_maven_cached_responses,
        :file_sha1,
        :binary,
        null: false, # rubocop: disable Rails/NotNullColumn -- The related model has a presence validation
        if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :virtual_registries_packages_maven_cached_responses, :file_md5, if_exists: true
      remove_column :virtual_registries_packages_maven_cached_responses, :file_sha1, if_exists: true
    end
  end
end
