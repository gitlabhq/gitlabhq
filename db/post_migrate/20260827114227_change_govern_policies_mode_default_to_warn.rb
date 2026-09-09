# frozen_string_literal: true

class ChangeGovernPoliciesModeDefaultToWarn < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    # Mode enum: { audit: 0, warn: 1, enforce: 2 }
    change_column_default :govern_policies, :mode, from: 2, to: 1
  end
end
