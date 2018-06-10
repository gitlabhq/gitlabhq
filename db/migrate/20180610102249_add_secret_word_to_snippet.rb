class AddSecretWordToSnippet < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :snippets, :secret_word, :string
  end
end
