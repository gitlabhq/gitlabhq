# frozen_string_literal: true

class AddComponentIdToSbomOccurrences < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    # Code using this table has not been implemented yet.
    # The migration prior to this one ensures that it is empty.
    # rubocop:disable Rails/NotNullColumn
    add_column :sbom_occurrences, :component_id, :bigint, null: false
    # rubocop:enable Rails/NotNullColumn
  end

  def down
    remove_column :sbom_occurrences, :component_id
  end
end
