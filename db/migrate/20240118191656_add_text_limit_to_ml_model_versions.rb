# frozen_string_literal: true

class AddTextLimitToMlModelVersions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_text_limit :ml_model_versions, :semver_prerelease, 255
  end

  def down
    remove_text_limit :ml_model_versions, :semver_prerelease
  end
end
