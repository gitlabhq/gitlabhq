# frozen_string_literal: true

class AddEncryptedRunnersTokenToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :runners_token_encrypted, :string
  end
end
