# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateWikiPageUserMentions < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '17.5'

  def up
    create_table :wiki_page_meta_user_mentions do |t| # rubocop:disable Migration/EnsureFactoryForTable -- No factory needed
      t.bigint :wiki_page_meta_id, null: false
      t.bigint :note_id, null: false
      t.bigint :namespace_id, null: false
      t.bigint :mentioned_users_ids, array: true, default: nil
      t.bigint :mentioned_projects_ids, array: true, default: nil
      t.bigint :mentioned_groups_ids, array: true, default: nil

      t.index :note_id
      t.index :namespace_id
      t.index [:wiki_page_meta_id, :note_id],
        unique: true,
        name: :index_wiki_meta_user_mentions_on_wiki_page_meta_id_and_note_id
    end
  end

  def down
    drop_table :wiki_page_meta_user_mentions, if_exists: true
  end
end
