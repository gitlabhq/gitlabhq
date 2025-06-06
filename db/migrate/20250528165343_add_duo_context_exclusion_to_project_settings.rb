# frozen_string_literal: true

class AddDuoContextExclusionToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :project_settings, :duo_context_exclusion_settings, :jsonb, null: false, default: {}
  end
end
