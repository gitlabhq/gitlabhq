# frozen_string_literal: true

class AddMatchOnInclusionToScanResultPolicy < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :scan_result_policies, :match_on_inclusion, :boolean
  end
end
