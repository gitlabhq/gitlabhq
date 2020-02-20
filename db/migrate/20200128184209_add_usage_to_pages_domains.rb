# frozen_string_literal: true

class AddUsageToPagesDomains < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  PAGES_USAGE = 0

  disable_ddl_transaction!

  def up
    add_column_with_default :pages_domains, :usage, :integer, limit: 2, default: PAGES_USAGE, allow_null: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :pages_domains, :usage
  end
end
