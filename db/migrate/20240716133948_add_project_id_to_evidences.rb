# frozen_string_literal: true

class AddProjectIdToEvidences < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :evidences, :project_id, :bigint
  end
end
