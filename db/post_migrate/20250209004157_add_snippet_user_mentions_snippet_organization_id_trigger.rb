# frozen_string_literal: true

class AddSnippetUserMentionsSnippetOrganizationIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :snippet_user_mentions,
      sharding_key: :snippet_organization_id,
      parent_table: :snippets,
      parent_sharding_key: :organization_id,
      foreign_key: :snippet_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :snippet_user_mentions,
      sharding_key: :snippet_organization_id,
      parent_table: :snippets,
      parent_sharding_key: :organization_id,
      foreign_key: :snippet_id
    )
  end
end
