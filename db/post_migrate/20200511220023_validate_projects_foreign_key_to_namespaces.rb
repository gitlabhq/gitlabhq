# frozen_string_literal: true

class ValidateProjectsForeignKeyToNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  FK_NAME = 'fk_projects_namespace_id'

  def up
    # Validate the FK added with 20200511080113_add_projects_foreign_key_to_namespaces.rb
    validate_foreign_key :projects, :namespace_id, name: FK_NAME
  end

  def down
    # no-op: No need to invalidate the foreign key
    # The inconsistent data are permanently fixed with the data migration
    #  `20200511083541_cleanup_projects_with_missing_namespace.rb`
    # even if it is rolled back.
    # If there is an issue with the FK, we'll roll back the migration that adds the FK
  end
end
