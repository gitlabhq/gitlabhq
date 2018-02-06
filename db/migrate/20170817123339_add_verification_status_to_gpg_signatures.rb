class AddVerificationStatusToGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    # First we remove all signatures because we need to re-verify them all
    # again anyway (because of the updated verification logic).
    #
    # This makes adding the column with default values faster
    truncate(:gpg_signatures)

    add_column_with_default(:gpg_signatures, :verification_status, :smallint, default: 0)
  end

  def down
    remove_column(:gpg_signatures, :verification_status)
  end
end
