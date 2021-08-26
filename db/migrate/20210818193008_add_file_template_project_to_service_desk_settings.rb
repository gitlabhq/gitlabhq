# frozen_string_literal: true

class AddFileTemplateProjectToServiceDeskSettings < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :service_desk_settings, :file_template_project_id, :bigint, null: true
  end
end
