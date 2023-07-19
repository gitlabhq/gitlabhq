# frozen_string_literal: true

class EventsBigintCreateIndexeAsyncForGitlabDotCom < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  def up
    return unless should_run?

    prepare_async_index :events,
      [:target_type, :target_id_convert_to_bigint, :fingerprint],
      name: :index_events_on_target_type_and_target_id_bigint_fingerprint,
      unique: true
  end

  def down
    return unless should_run?

    unprepare_async_index :events,
      [:target_type, :target_id_convert_to_bigint, :fingerprint],
      name: :index_events_on_target_type_and_target_id_bigint_fingerprint
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
