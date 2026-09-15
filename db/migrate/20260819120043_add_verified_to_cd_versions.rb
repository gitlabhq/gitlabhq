# frozen_string_literal: true

class AddVerifiedToCdVersions < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :cd_versions, :verified, :boolean, default: true, null: false
  end
end
