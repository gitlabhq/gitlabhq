# frozen_string_literal: true

class MakeComponentVersionNullable < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    change_column_null :sbom_occurrences, :component_version_id, true
  end
end
