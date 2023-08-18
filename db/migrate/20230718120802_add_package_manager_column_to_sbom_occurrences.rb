# frozen_string_literal: true

class AddPackageManagerColumnToSbomOccurrences < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :sbom_occurrences, :package_manager, :text, if_not_exists: true
    end

    add_text_limit :sbom_occurrences, :package_manager, 255
  end

  def down
    remove_column :sbom_occurrences, :package_manager, if_exists: true
  end
end
