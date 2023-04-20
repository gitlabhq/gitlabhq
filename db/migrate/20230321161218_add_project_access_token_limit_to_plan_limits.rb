# frozen_string_literal: true

class AddProjectAccessTokenLimitToPlanLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column(:plan_limits, :project_access_token_limit, :integer, default: 0, null: false)
  end
end
