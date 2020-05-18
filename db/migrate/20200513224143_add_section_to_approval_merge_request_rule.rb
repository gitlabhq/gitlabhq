# frozen_string_literal: true

class AddSectionToApprovalMergeRequestRule < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:approval_merge_request_rules, :section)
      add_column :approval_merge_request_rules, :section, :text
    end

    add_text_limit :approval_merge_request_rules, :section, 255
  end

  def down
    remove_column :approval_merge_request_rules, :section
  end
end
