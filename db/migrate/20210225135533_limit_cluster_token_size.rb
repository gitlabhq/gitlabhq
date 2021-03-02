# frozen_string_literal: true

class LimitClusterTokenSize < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :cluster_agent_tokens, :name, 255
  end

  def down
    remove_text_limit :cluster_agent_tokens, :name
  end
end
