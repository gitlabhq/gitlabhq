# frozen_string_literal: true

class AddLastRolloutIidToCdApplications < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :cd_applications, :last_rollout_iid, :integer, default: 0, null: false
  end
end
