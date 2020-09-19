# frozen_string_literal: true

class AddCiJobArtifactIdToPagesMetadata < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:project_pages_metadata, :artifacts_archive_id, :bigint)
  end
end
