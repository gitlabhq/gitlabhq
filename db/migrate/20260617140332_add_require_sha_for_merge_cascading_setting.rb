# frozen_string_literal: true

class AddRequireShaForMergeCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :require_sha_for_merge, :boolean, default: false, null: false
  end

  def down
    remove_cascading_namespace_setting :require_sha_for_merge
  end
end
