class DestroyGpgSignatures < ActiveRecord::Migration
  DOWNTIME = false

  def up
    truncate(:gpg_signatures)
  end

  def down
  end
end
