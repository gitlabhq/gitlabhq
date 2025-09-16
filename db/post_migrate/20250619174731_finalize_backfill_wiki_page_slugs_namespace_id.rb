# frozen_string_literal: true

class FinalizeBackfillWikiPageSlugsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillWikiPageSlugsNamespaceId',
      table_name: :wiki_page_slugs,
      column_name: :id,
      job_arguments: [:namespace_id, :wiki_page_meta, :namespace_id, :wiki_page_meta_id],
      finalize: true
    )
  end

  def down; end
end
