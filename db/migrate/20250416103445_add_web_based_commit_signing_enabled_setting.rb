# frozen_string_literal: true

class AddWebBasedCommitSigningEnabledSetting < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  milestone '18.0'

  def up
    add_cascading_namespace_setting :web_based_commit_signing_enabled, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :web_based_commit_signing_enabled
  end
end
