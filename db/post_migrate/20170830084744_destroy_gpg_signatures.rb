class DestroyGpgSignatures < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    truncate(:gpg_signatures)
  end

  def down
  end
end
