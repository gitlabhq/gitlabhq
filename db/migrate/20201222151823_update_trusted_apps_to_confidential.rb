# frozen_string_literal: true

class UpdateTrustedAppsToConfidential < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'tmp_index_oauth_applications_on_id_where_trusted'

  disable_ddl_transaction!

  def up
    add_concurrent_index :oauth_applications, :id, where: 'trusted = true', name: INDEX_NAME

    execute('UPDATE oauth_applications SET confidential = true WHERE trusted = true')
  end

  def down
    # We won't be able to tell which trusted applications weren't confidential before the migration
    # and setting all trusted applications are not confidential would introduce security issues

    remove_concurrent_index_by_name :oauth_applications, INDEX_NAME
  end
end
