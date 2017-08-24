class AddVerificationStatusToGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :gpg_signatures, :verification_status, :smallint
  end
end
