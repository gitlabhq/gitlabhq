# frozen_string_literal: true

class AddTextLimitToNamespaceSettingsDefaultBranchName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :namespace_settings, :default_branch_name, 255
  end

  def down
    # Down is required as `add_text_limit` is not reversible
    #
    remove_text_limit :namespace_settings, :default_branch_name
  end
end
