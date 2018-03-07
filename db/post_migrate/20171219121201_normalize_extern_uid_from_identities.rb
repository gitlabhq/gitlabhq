# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class NormalizeExternUidFromIdentities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'NormalizeLdapExternUidsRange'.freeze
  DELAY_INTERVAL = 10.seconds

  disable_ddl_transaction!

  class Identity < ActiveRecord::Base
    include EachBatch

    self.table_name = 'identities'
  end

  def up
    ldap_identities = Identity.where("provider like 'ldap%'")

    if ldap_identities.any?
      queue_background_migration_jobs_by_range_at_intervals(Identity, MIGRATION, DELAY_INTERVAL)
    end
  end

  def down
  end
end
