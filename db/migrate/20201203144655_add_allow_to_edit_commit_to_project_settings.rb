# frozen_string_literal: true

class AddAllowToEditCommitToProjectSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # no-op
  end

  def down
    # no-op
  end
end
