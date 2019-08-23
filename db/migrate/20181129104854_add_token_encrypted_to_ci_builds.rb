# frozen_string_literal: true

class AddTokenEncryptedToCiBuilds < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_builds, :token_encrypted, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
