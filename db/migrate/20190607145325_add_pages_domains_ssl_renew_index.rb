# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPagesDomainsSslRenewIndex < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  INDEX_NAME = 'index_pages_domains_need_auto_ssl_renewal'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:pages_domains, [:certificate_source, :certificate_valid_not_after],
                         where: "auto_ssl_enabled = #{::Gitlab::Database.true_value}", name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:pages_domains, [:certificate_source, :certificate_valid_not_after],
                            where: "auto_ssl_enabled = #{::Gitlab::Database.true_value}", name: INDEX_NAME)
  end
end
