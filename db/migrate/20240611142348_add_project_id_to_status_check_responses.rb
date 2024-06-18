# frozen_string_literal: true

class AddProjectIdToStatusCheckResponses < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :status_check_responses, :project_id, :bigint
  end
end
