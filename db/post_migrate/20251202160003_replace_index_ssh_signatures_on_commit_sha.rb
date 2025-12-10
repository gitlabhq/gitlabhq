# frozen_string_literal: true

class ReplaceIndexSshSignaturesOnCommitSha < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    # No-op
  end

  def down
    # No-op
  end
end
