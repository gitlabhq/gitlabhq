# frozen_string_literal: true

class AddDuoTemplateProjectIdToNamespaceTemplateSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :namespace_template_settings, :duo_template_project_id, :bigint
  end
end
