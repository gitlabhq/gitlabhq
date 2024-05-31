# frozen_string_literal: true

class AddWikiPageSlugsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :wiki_page_slugs,
      sharding_key: :project_id,
      parent_table: :wiki_page_meta,
      parent_sharding_key: :project_id,
      foreign_key: :wiki_page_meta_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :wiki_page_slugs,
      sharding_key: :project_id,
      parent_table: :wiki_page_meta,
      parent_sharding_key: :project_id,
      foreign_key: :wiki_page_meta_id
    )
  end
end
