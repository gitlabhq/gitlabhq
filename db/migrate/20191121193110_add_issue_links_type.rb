# frozen_string_literal: true

class AddIssueLinksType < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :issue_links, :link_type, :integer, default: 0, limit: 2 # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :issue_links, :link_type
  end
end
