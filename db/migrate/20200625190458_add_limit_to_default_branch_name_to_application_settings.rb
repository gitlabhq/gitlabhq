# frozen_string_literal: true

class AddLimitToDefaultBranchNameToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :default_branch_name, 255
  end

  def down
    remove_text_limit :application_settings, :default_branch_name
  end
end
