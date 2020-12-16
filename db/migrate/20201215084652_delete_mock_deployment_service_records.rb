# frozen_string_literal: true

class DeleteMockDeploymentServiceRecords < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    if Rails.env.development?
      execute("DELETE FROM services WHERE type = 'MockDeploymentService'")
    end
  end

  def down
    # no-op
  end
end
