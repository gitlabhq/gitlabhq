# frozen_string_literal: true

class AddExpandedEnvironmentNameToCiBuildMetadata < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def up
    add_column :ci_builds_metadata, :expanded_environment_name, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column :ci_builds_metadata, :expanded_environment_name
  end
end
