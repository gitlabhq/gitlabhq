# rubocop:disable RemoveIndex
class AddUniqueIndexToLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration removes duplicated labels.'

  disable_ddl_transaction!

  def up
    select_all('SELECT title, project_id, COUNT(id) as cnt FROM labels GROUP BY project_id, title HAVING COUNT(id) > 1').each do |label|
      label_title = quote_string(label['title'])
      duplicated_ids = select_all("SELECT id FROM labels WHERE project_id = #{label['project_id']} AND title = '#{label_title}' ORDER BY id ASC").map { |label| label['id'] }
      label_id = duplicated_ids.first
      duplicated_ids.delete(label_id)

      execute("UPDATE label_links SET label_id = #{label_id} WHERE label_id IN(#{duplicated_ids.join(",")})")
      execute("DELETE FROM labels WHERE id IN(#{duplicated_ids.join(",")})")
    end

    remove_index :labels, column: :project_id if index_exists?(:labels, :project_id)
    remove_index :labels, column: :title if index_exists?(:labels, :title)

    add_concurrent_index :labels, [:group_id, :project_id, :title], unique: true
  end

  def down
    remove_index :labels, column: [:group_id, :project_id, :title] if index_exists?(:labels, [:group_id, :project_id, :title], unique: true)

    add_concurrent_index :labels, :project_id
    add_concurrent_index :labels, :title
  end
end
