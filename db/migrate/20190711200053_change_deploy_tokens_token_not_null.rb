# frozen_string_literal: true

class ChangeDeployTokensTokenNotNull < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_column_null :deploy_tokens, :token, true
  end
end
