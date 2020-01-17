# frozen_string_literal: true

class AddGroupIndexAndFkToImportFailures < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  GROUP_INDEX = 'index_import_failures_on_group_id_not_null'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index(:import_failures, :group_id, where: 'group_id IS NOT NULL', name: GROUP_INDEX)

    add_concurrent_foreign_key(:import_failures, :namespaces, column: :group_id)
  end

  def down
    remove_foreign_key(:import_failures, column: :group_id)

    remove_concurrent_index_by_name(:import_failures, GROUP_INDEX)
  end
end
