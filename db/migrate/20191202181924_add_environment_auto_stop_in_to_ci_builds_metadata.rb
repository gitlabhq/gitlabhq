# frozen_string_literal: true

class AddEnvironmentAutoStopInToCiBuildsMetadata < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :ci_builds_metadata, :environment_auto_stop_in, :string, limit: 255
  end

  def down
    remove_column :ci_builds_metadata, :environment_auto_stop_in
  end
end
