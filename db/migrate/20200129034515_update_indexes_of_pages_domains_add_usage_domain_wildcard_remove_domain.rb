# frozen_string_literal: true

class UpdateIndexesOfPagesDomainsAddUsageDomainWildcardRemoveDomain < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :pages_domains, :usage
    add_concurrent_index :pages_domains, [:domain, :wildcard], unique: true
    remove_concurrent_index :pages_domains, :domain
  end

  def down
    remove_concurrent_index :pages_domains, :usage
    remove_concurrent_index :pages_domains, [:domain, :wildcard]
    add_concurrent_index :pages_domains, :domain, unique: true
  end
end
