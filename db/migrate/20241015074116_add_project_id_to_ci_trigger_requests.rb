# frozen_string_literal: true

class AddProjectIdToCiTriggerRequests < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column(:ci_trigger_requests, :project_id, :bigint)
  end
end
