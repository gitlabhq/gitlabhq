# frozen_string_literal: true

class AddModelPromptCacheEnabledCascadingSetting < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  milestone '18.0'

  def up
    add_cascading_namespace_setting :model_prompt_cache_enabled, :boolean, default: true, null: false
  end

  def down
    remove_cascading_namespace_setting :model_prompt_cache_enabled
  end
end
# frozen_string_literal: true
