# frozen_string_literal: true

class AddNameFieldToClusterAgentToken < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in LimitClusterTokenSize
  def change
    add_column :cluster_agent_tokens, :name, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
