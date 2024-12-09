# frozen_string_literal: true

class AddPipelinesTriggerId < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column(:p_ci_pipelines, :trigger_id, :bigint)
  end
end
