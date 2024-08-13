# frozen_string_literal: true

class AddDuoWorkflowToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :application_settings, :duo_workflow, :jsonb, default: {}, null: true
  end
end
