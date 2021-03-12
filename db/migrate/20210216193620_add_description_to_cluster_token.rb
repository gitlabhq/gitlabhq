# frozen_string_literal: true

class AddDescriptionToClusterToken < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:cluster_agent_tokens, :description)
      add_column :cluster_agent_tokens, :description, :text
    end

    add_text_limit :cluster_agent_tokens, :description, 1024
  end

  def down
    remove_column :cluster_agent_tokens, :description
  end
end
