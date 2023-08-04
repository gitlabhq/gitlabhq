# frozen_string_literal: true

class AddComponentNameAndInputFilePathToSbomOccurrences < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :sbom_occurrences, :component_name, :text, if_not_exists: true
      add_column :sbom_occurrences, :input_file_path, :text, if_not_exists: true
    end

    add_text_limit :sbom_occurrences, :component_name, 255
    add_text_limit :sbom_occurrences, :input_file_path, 255
  end

  def down
    with_lock_retries do
      remove_column :sbom_occurrences, :component_name, if_exists: true
      remove_column :sbom_occurrences, :input_file_path, if_exists: true
    end
  end
end
