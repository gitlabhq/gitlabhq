# frozen_string_literal: true

# rubocop: disable Migration/AddConcurrentForeignKey

class UpdateInsightsForeignKeys < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_foreign_key_if_exists(:insights, column: :project_id)
    add_foreign_key(:insights, :projects, column: :project_id, on_delete: :cascade)

    remove_foreign_key_if_exists(:insights, column: :namespace_id)
    add_foreign_key(:insights, :namespaces, column: :namespace_id, on_delete: :cascade)
  end

  def down
    remove_foreign_key_if_exists(:insights, column: :namespace_id)
    add_foreign_key(:insights, :namespaces, column: :namespace_id)

    remove_foreign_key_if_exists(:insights, column: :project_id)
    add_foreign_key(:insights, :projects, column: :project_id)
  end
end
