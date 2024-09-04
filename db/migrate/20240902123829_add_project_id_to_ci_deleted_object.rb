# frozen_string_literal: true

class AddProjectIdToCiDeletedObject < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column(:ci_deleted_objects, :project_id, :bigint)
  end
end
