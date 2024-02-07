# frozen_string_literal: true

class IncreaseSbomOccurrenceInputFileNameLimit < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  def up
    add_text_limit(:sbom_occurrences, :input_file_path, 1024,
      constraint_name: check_constraint_name(:sbom_occurrences, :input_file_path, 'max_length_1KiB'))
    remove_text_limit :sbom_occurrences, :input_file_path,
      constraint_name: check_constraint_name(:sbom_occurrences, :input_file_path, 'max_length')
  end

  def down
    # no-op: Danger of failing if there are records with length(input_file_path) > 255
  end
end
