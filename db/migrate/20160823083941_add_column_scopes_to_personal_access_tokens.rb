# The default needs to be `[]`, but all existing access tokens need to have `scopes` set to `['api']`.
# It's easier to achieve this by adding the column with the `['api']` default, and then changing the default to
# `[]`.

class AddColumnScopesToPersonalAccessTokens < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :personal_access_tokens, :scopes, :string, default: ['api'].to_yaml
  end

  def down
    remove_column :personal_access_tokens, :scopes
  end
end
