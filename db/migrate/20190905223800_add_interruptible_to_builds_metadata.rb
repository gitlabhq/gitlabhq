# frozen_string_literal: true

class AddInterruptibleToBuildsMetadata < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :ci_builds_metadata, :interruptible, :boolean
  end
end
