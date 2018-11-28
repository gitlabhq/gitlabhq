class RemoveEmptyExternUidAuth0Identities < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Identity < ActiveRecord::Base
    self.table_name = 'identities'
    include EachBatch
  end

  def up
    broken_auth0_identities.each_batch do |identity|
      identity.delete_all
    end
  end

  def broken_auth0_identities
    Identity.where(provider: 'auth0', extern_uid: [nil, ''])
  end

  def down
  end
end
