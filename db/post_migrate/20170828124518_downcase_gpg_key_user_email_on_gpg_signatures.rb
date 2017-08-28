class DowncaseGpgKeyUserEmailOnGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  class GpgSignature < ActiveRecord::Base
    self.table_name = 'gpg_signatures'

    include EachBatch
  end

  def up
    GpgSignature.each_batch do |relation|
      relation.update_all('gpg_key_user_email = LOWER(gpg_key_user_email)')
    end
  end

  def down
    # we can't revert the downcasing, but actually we don't need to really, as
    # downcasing the emails is not a harmful change.
  end
end
