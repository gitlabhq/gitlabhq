# frozen_string_literal: true

class RemoveIssuesExternalKey < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    remove_column :issues, :external_key
  end

  def down
    add_column :issues, :external_key, :string, limit: 255
  end
end
