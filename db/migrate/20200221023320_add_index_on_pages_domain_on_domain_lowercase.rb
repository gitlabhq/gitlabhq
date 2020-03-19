# frozen_string_literal: true

class AddIndexOnPagesDomainOnDomainLowercase < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_pages_domains_on_domain_lowercase'

  disable_ddl_transaction!

  def up
    add_concurrent_index :pages_domains, 'LOWER(domain)', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :pages_domains, INDEX_NAME
  end
end
