# frozen_string_literal: true

class AddWikiPageMetaUserMentionsNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    install_sharding_key_assignment_trigger(
      table: :wiki_page_meta_user_mentions,
      sharding_key: :namespace_id,
      parent_table: :notes,
      parent_sharding_key: :namespace_id,
      foreign_key: :note_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :wiki_page_meta_user_mentions,
      sharding_key: :namespace_id,
      parent_table: :notes,
      parent_sharding_key: :namespace_id,
      foreign_key: :note_id
    )
  end
end
