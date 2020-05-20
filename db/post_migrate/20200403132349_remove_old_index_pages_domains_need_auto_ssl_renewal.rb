# frozen_string_literal: true

class RemoveOldIndexPagesDomainsNeedAutoSslRenewal < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_pages_domains_need_auto_ssl_renewal'

  disable_ddl_transaction!

  def up
    remove_concurrent_index(:pages_domains, [:certificate_source, :certificate_valid_not_after],
                            where: "auto_ssl_enabled = true", name: INDEX_NAME)
  end

  def down
    add_concurrent_index(:pages_domains, [:certificate_source, :certificate_valid_not_after],
                         where: "auto_ssl_enabled = true", name: INDEX_NAME)
  end
end
