# frozen_string_literal: true

class AddDuoFeaturesEnabledCascadingSetting < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings
  enable_lock_retries!

  milestone '16.10'

  def up
    add_cascading_namespace_setting :duo_features_enabled, :boolean, default: true, null: false
  end

  def down
    remove_cascading_namespace_setting :duo_features_enabled
  end
end
