# frozen_string_literal: true

class SwapColumnsForPCiBuildsTriggerRequestAndErasedBy < Gitlab::Database::Migration[2.2]
  include ::Gitlab::Database::MigrationHelpers::Swapping
  milestone '17.1'
  disable_ddl_transaction!

  TABLE = :p_ci_builds
  COLUMNS = [
    { name: :trigger_request_id_convert_to_bigint, old_name: :trigger_request_id },
    { name: :erased_by_id_convert_to_bigint, old_name: :erased_by_id }
  ]
  TRIGGER_FUNCTION = :trigger_10ee1357e825

  def up
    with_lock_retries(raise_on_exhaustion: true) do
      swap # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    end
  end

  def down
    with_lock_retries(raise_on_exhaustion: true) do
      swap # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- custom implementation
    end
  end

  private

  def swap
    lock_tables(TABLE)

    COLUMNS.each do |column|
      swap_columns(TABLE, column[:name], column[:old_name])
    end
    reset_trigger_function(TRIGGER_FUNCTION)
  end
end
