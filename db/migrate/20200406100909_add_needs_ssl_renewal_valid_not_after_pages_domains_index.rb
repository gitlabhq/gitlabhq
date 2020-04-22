# frozen_string_literal: true

class AddNeedsSslRenewalValidNotAfterPagesDomainsIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_pages_domains_need_auto_ssl_renewal_valid_not_after'
  INDEX_SCOPE = "auto_ssl_enabled = true AND auto_ssl_failed = false"

  disable_ddl_transaction!

  def up
    add_concurrent_index(:pages_domains, :certificate_valid_not_after, where: INDEX_SCOPE, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:pages_domains, :certificate_valid_not_after, where: INDEX_SCOPE, name: INDEX_NAME)
  end
end
