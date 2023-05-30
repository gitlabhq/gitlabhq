# frozen_string_literal: true

class CleanupNotesBigintPreparation < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  def up
    return unless should_run?

    remove_concurrent_index_by_name(
      :merge_request_user_mentions,
      :index_merge_request_user_mentions_note_id_convert_to_bigint,
      if_exists: true
    )

    remove_concurrent_index_by_name(
      :issue_user_mentions,
      :index_issue_user_mentions_on_note_id_convert_to_bigint,
      if_exists: true
    )

    with_lock_retries do
      remove_foreign_key_if_exists(
        :issue_user_mentions,
        :notes,
        name: :fk_issue_user_mentions_note_id_convert_to_bigint,
        reverse_lock_order: true
      )
    end

    with_lock_retries do
      remove_foreign_key_if_exists(
        :merge_request_user_mentions,
        :notes,
        name: :fk_merge_request_user_mentions_note_id_convert_to_bigint,
        reverse_lock_order: true
      )
    end
  end

  def down
    # No-op
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
