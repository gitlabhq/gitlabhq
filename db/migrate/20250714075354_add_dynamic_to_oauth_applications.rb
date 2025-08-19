# frozen_string_literal: true

class AddDynamicToOauthApplications < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    add_column :oauth_applications, :dynamic, :boolean, default: false, null: false
  end

  def down
    remove_column :oauth_applications, :dynamic
  end
end
