# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveOperationsFeatureFlagScopesForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    with_lock_retries do
      remove_foreign_key :operations_feature_flag_scopes, :operations_feature_flags
    end
  end

  def down
    add_concurrent_foreign_key :operations_feature_flag_scopes, :operations_feature_flags, column: :feature_flag_id,
      name: 'fk_rails_a50a04d0a4'
  end
end
