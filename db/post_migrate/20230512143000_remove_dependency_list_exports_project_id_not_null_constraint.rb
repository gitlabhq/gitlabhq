# frozen_string_literal: true

class RemoveDependencyListExportsProjectIdNotNullConstraint < Gitlab::Database::Migration[2.1]
  def up
    change_column_null :dependency_list_exports, :project_id, true
  end

  def down
    # no-op as there can be null values after the migration
  end
end
