# frozen_string_literal: true

class AddTokenEncryptedToCiRunners < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_runners, :token_encrypted, :string # rubocop:disable Migration/PreventStrings
  end
end
