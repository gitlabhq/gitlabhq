class ConvertAwardNoteToEmojiAward < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    if Gitlab::Database.postgresql?
      migrate_postgresql
    else
      migrate_mysql
    end
  end

  def down
    add_column :notes, :is_award, :boolean

    # This migration does NOT move the awards on notes, if the table is dropped in another migration, these notes will be lost.
    execute "INSERT INTO notes (noteable_type, noteable_id, author_id, note, created_at, updated_at, is_award) (SELECT awardable_type, awardable_id, user_id, name, created_at, updated_at, TRUE FROM award_emoji)"
  end

  def migrate_postgresql
    connection.transaction do
      execute 'LOCK notes IN EXCLUSIVE MODE'
      execute "INSERT INTO award_emoji (awardable_type, awardable_id, user_id, name, created_at, updated_at) (SELECT noteable_type, noteable_id, author_id, note, created_at, updated_at FROM notes WHERE is_award = true)"
      execute "DELETE FROM notes WHERE is_award = true"
      remove_column :notes, :is_award, :boolean
    end
  end

  def migrate_mysql
    execute 'LOCK TABLES notes WRITE, award_emoji WRITE;'
    execute 'INSERT INTO award_emoji (awardable_type, awardable_id, user_id, name, created_at, updated_at) (SELECT noteable_type, noteable_id, author_id, note, created_at, updated_at FROM notes WHERE is_award = true);'
    execute "DELETE FROM notes WHERE is_award = true"
    remove_column :notes, :is_award, :boolean
  ensure
    execute 'UNLOCK TABLES'
  end
end
