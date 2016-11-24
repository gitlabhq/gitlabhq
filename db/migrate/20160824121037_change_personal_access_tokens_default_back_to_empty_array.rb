# The default needs to be `[]`, but all existing access tokens need to have `scopes` set to `['api']`.
# It's easier to achieve this by adding the column with the `['api']` default, and then changing the default to
# `[]`.

class ChangePersonalAccessTokensDefaultBackToEmptyArray < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :personal_access_tokens, :scopes, [].to_yaml
  end

  def down
    change_column_default :personal_access_tokens, :scopes, ['api'].to_yaml
  end
end
