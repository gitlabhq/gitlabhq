# frozen_string_literal: true

class AddNameToCdArtifactSources < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  def up
    add_column :cd_artifact_sources, :name, :text, if_not_exists: true

    add_text_limit :cd_artifact_sources, :name, 255
  end

  def down
    remove_text_limit :cd_artifact_sources, :name
    remove_column :cd_artifact_sources, :name, if_exists: true
  end
end
