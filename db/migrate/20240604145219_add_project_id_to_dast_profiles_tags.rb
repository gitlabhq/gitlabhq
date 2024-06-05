# frozen_string_literal: true

class AddProjectIdToDastProfilesTags < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :dast_profiles_tags, :project_id, :bigint
  end
end
