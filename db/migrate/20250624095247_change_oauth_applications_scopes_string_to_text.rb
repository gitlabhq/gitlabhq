# frozen_string_literal: true

class ChangeOauthApplicationsScopesStringToText < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def up
    change_column :oauth_applications, :scopes, :text, default: '', null: false
  end

  def down
    change_column :oauth_applications, :scopes, :string, default: '', null: false
  end
end
