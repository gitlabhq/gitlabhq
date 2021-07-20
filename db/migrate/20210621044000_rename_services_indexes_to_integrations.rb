# frozen_string_literal: true

class RenameServicesIndexesToIntegrations < ActiveRecord::Migration[6.1]
  INDEXES = %w(
    project_and_type_where_inherit_null
    project_id_and_type_unique
    template
    type
    type_and_instance_partial
    type_and_template_partial
    type_id_when_active_and_project_id_not_null
    unique_group_id_and_type
  ).freeze

  def up
    INDEXES.each do |index|
      execute(<<~SQL)
        ALTER INDEX IF EXISTS "index_services_on_#{index}" RENAME TO "index_integrations_on_#{index}"
      SQL
    end
  end

  def down
    INDEXES.each do |index|
      execute(<<~SQL)
        ALTER INDEX IF EXISTS "index_integrations_on_#{index}" RENAME TO "index_services_on_#{index}"
      SQL
    end
  end
end
