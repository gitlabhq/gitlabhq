# frozen_string_literal: true

class AddVersionPartsToModelVersions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_column :ml_model_versions, :semver_major, :integer
    add_column :ml_model_versions, :semver_minor, :integer
    add_column :ml_model_versions, :semver_patch, :integer
    add_column :ml_model_versions, :semver_prerelease, :text # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in 20240118191656_add_text_limit_to_ml_model_versions.rb
  end

  def down
    remove_column :ml_model_versions, :semver_major, :integer
    remove_column :ml_model_versions, :semver_minor, :integer
    remove_column :ml_model_versions, :semver_patch, :integer
    remove_column :ml_model_versions, :semver_prerelease, :text
  end
end
