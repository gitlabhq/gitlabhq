# frozen_string_literal: true

class RemoveTemporaryIndexForSnippets < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  def up
    return unless Gitlab.com?

    remove_concurrent_index_by_name :snippets, 'tmp_index_snippets_for_organization_id'
  end

  def down
    return unless Gitlab.com?

    add_concurrent_index :snippets, :id,
      where: "type = 'ProjectSnippet' and organization_id IS NOT NULL",
      name: 'tmp_index_snippets_for_organization_id'
  end
end
