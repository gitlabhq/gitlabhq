# frozen_string_literal: true

class AddIndexesToPagesDomainsOnWildcardAndDomainType < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :pages_domains, :wildcard
    add_concurrent_index :pages_domains, :domain_type
  end

  def down
    remove_concurrent_index :pages_domains, :wildcard
    remove_concurrent_index :pages_domains, :domain_type
  end
end
