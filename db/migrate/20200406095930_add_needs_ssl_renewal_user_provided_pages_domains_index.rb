# frozen_string_literal: true

class AddNeedsSslRenewalUserProvidedPagesDomainsIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_pages_domains_need_auto_ssl_renewal_user_provided'
  INDEX_SCOPE = "auto_ssl_enabled = true AND auto_ssl_failed = false AND certificate_source = 0"

  disable_ddl_transaction!

  def up
    add_concurrent_index(:pages_domains, :id, where: INDEX_SCOPE, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:pages_domains, :id, where: INDEX_SCOPE, name: INDEX_NAME)
  end
end
