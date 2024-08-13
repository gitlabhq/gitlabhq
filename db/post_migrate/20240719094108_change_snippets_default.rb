# frozen_string_literal: true

class ChangeSnippetsDefault < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1

  milestone '17.3'

  def change
    change_column_default('snippets', 'organization_id', from: DEFAULT_ORGANIZATION_ID, to: nil)
  end
end
