class DestroyGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  class GpgSignature < ActiveRecord::Base
    self.table_name = 'gpg_signatures'

    include EachBatch
  end

  def up
    GpgSignature.each_batch do |relation|
      relation.delete_all
    end
  end

  def down
  end
end
