# frozen_string_literal: true

class AddTokenEncryptedToCiRunners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_runners, :token_encrypted, :string
  end
end
