# frozen_string_literal: true

class NotesBigintCreateIndexesAsyncForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  TABLE_NAME = 'notes'
  PK_INDEX_NAME = 'index_notes_on_id_convert_to_bigint'

  SECONDARY_INDEXES = [
    {
      name: :index_notes_on_author_id_created_at_id_convert_to_bigint,
      columns: [:author_id, :created_at, :id_convert_to_bigint],
      options: {}
    },
    {
      name: :index_notes_on_id_convert_to_bigint_where_confidential,
      columns: [:id_convert_to_bigint],
      options: { where: 'confidential = true' }
    },
    {
      name: :index_notes_on_id_convert_to_bigint_where_internal,
      columns: [:id_convert_to_bigint],
      options: { where: 'internal = true' }
    },
    {
      name: :index_notes_on_project_id_id_convert_to_bigint_system_false,
      columns: [:project_id, :id_convert_to_bigint],
      options: { where: 'NOT system' }
    },
    {
      name: :note_mentions_temp_index_convert_to_bigint,
      columns: [:id_convert_to_bigint, :noteable_type],
      options: { where: "note ~~ '%@%'::text" }
    }
  ]

  # Indexes will be created synchronously in
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119705
  def up
    return unless should_run?

    prepare_async_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: PK_INDEX_NAME

    SECONDARY_INDEXES.each do |index|
      prepare_async_index TABLE_NAME, index[:columns], **index[:options].merge(name: index[:name])
    end
  end

  def down
    return unless should_run?

    SECONDARY_INDEXES.each do |index|
      unprepare_async_index TABLE_NAME, index[:columns], name: index[:name]
    end

    unprepare_async_index TABLE_NAME, :id_convert_to_bigint, name: PK_INDEX_NAME
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
