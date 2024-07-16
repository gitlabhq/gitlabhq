# frozen_string_literal: true

class AddProjectIdToProtectedTagCreateAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :protected_tag_create_access_levels, :project_id, :bigint
  end
end
