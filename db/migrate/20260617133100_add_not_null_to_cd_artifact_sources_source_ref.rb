# frozen_string_literal: true

class AddNotNullToCdArtifactSourcesSourceRef < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_not_null_constraint :cd_artifact_sources, :source_ref
  end

  def down
    remove_not_null_constraint :cd_artifact_sources, :source_ref
  end
end
