# frozen_string_literal: true

class AddReferencingBigintFksForNotesOnGitlabCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  REFERENCING_FOREIGN_KEYS = [
    [:todos, :fk_91d1f47b13, :note_id, :cascade],
    [:incident_management_timeline_events, :fk_d606a2a890, :promoted_from_note_id, :nullify],
    [:system_note_metadata, :fk_d83a918cb1, :note_id, :cascade],
    [:diff_note_positions, :fk_rails_13c7212859, :note_id, :cascade],
    [:epic_user_mentions, :fk_rails_1c65976a49, :note_id, :cascade],
    [:suggestions, :fk_rails_33b03a535c, :note_id, :cascade],
    [:issue_user_mentions, :fk_rails_3861d9fefa, :note_id, :cascade],
    [:note_diff_files, :fk_rails_3d66047aeb, :diff_note_id, :cascade],
    [:snippet_user_mentions, :fk_rails_4d3f96b2cb, :note_id, :cascade],
    [:design_user_mentions, :fk_rails_8de8c6d632, :note_id, :cascade],
    [:vulnerability_user_mentions, :fk_rails_a18600f210, :note_id, :cascade],
    [:commit_user_mentions, :fk_rails_a6760813e0, :note_id, :cascade],
    [:merge_request_user_mentions, :fk_rails_c440b9ea31, :note_id, :cascade],
    [:note_metadata, :fk_rails_d853224d37, :note_id, :cascade],
    [:alert_management_alert_user_mentions, :fk_rails_eb2de0cdef, :note_id, :cascade],
    [:timelogs, :fk_timelogs_note_id, :note_id, :nullify]
  ]

  def up
    return unless should_run?

    REFERENCING_FOREIGN_KEYS.each do |(from_table, name, column, on_delete)|
      temporary_name = "#{name}_tmp"

      # This will replace the existing FKs when
      # we swap the integer and bigint columns in
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119705
      add_concurrent_foreign_key(
        from_table,
        :notes,
        column: column,
        target_column: :id_convert_to_bigint,
        name: temporary_name,
        on_delete: on_delete,
        reverse_lock_order: true,
        validate: false)

      prepare_async_foreign_key_validation from_table, column, name: temporary_name
    end
  end

  def down
    return unless should_run?

    REFERENCING_FOREIGN_KEYS.each do |(from_table, name, column, _)|
      temporary_name = "#{name}_tmp"

      unprepare_async_foreign_key_validation from_table, column, name: temporary_name

      with_lock_retries do
        remove_foreign_key_if_exists(
          from_table,
          :notes,
          name: temporary_name,
          reverse_lock_order: true
        )
      end
    end
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
