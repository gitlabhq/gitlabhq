# frozen_string_literal: true

class AddUsernameToDeployTokens < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :deploy_tokens, :username, :string
  end
end
