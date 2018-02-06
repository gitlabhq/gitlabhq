class RemoveValidSignatureFromGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  def up
    remove_column :gpg_signatures, :valid_signature
  end

  def down
    add_column :gpg_signatures, :valid_signature, :boolean
  end
end
