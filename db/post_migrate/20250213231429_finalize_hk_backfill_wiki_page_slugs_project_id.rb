# frozen_string_literal: true

class FinalizeHkBackfillWikiPageSlugsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillWikiPageSlugsProjectId',
      table_name: :wiki_page_slugs,
      column_name: :id,
      job_arguments: [:project_id, :wiki_page_meta, :project_id, :wiki_page_meta_id],
      finalize: true
    )
  end

  def down; end
end
