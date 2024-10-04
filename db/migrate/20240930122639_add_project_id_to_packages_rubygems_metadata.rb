# frozen_string_literal: true

class AddProjectIdToPackagesRubygemsMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :packages_rubygems_metadata, :project_id, :bigint
  end
end
