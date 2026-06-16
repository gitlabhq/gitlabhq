# frozen_string_literal: true

class AddDuoTemplateProjectIdToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    add_column :application_settings, :duo_template_project_id, :bigint
  end
end
