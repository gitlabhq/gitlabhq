# frozen_string_literal: true

class AddAutoSslEnabledToPagesDomain < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :pages_domains, :auto_ssl_enabled, :boolean, default: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :pages_domains, :auto_ssl_enabled
  end
end
