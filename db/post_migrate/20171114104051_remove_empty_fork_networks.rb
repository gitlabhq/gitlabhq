class RemoveEmptyForkNetworks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000

  class MigrationForkNetwork < ActiveRecord::Base
    include EachBatch

    self.table_name = 'fork_networks'
  end

  class MigrationForkNetworkMembers < ActiveRecord::Base
    self.table_name = 'fork_network_members'
  end

  disable_ddl_transaction!

  def up
    say 'Deleting empty ForkNetworks in batches'

    has_members = MigrationForkNetworkMembers
                    .where('fork_network_members.fork_network_id = fork_networks.id')
                    .select(1)
    MigrationForkNetwork.where('NOT EXISTS (?)', has_members)
      .each_batch(of: BATCH_SIZE) do |networks|
      deleted = networks.delete_all

      say "Deleted #{deleted} rows in batch"
    end
  end

  def down
    # nothing
  end
end
