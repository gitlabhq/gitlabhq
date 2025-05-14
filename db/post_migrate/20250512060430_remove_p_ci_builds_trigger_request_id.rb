# frozen_string_literal: true

class RemovePCiBuildsTriggerRequestId < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '18.1'

  TABLE = :p_ci_builds
  COLUMN = :trigger_request_id

  def up
    return unless can_execute_on?(:ci_builds)

    remove_column(TABLE, COLUMN)
  end

  def down
    return unless can_execute_on?(:ci_builds)

    add_column(TABLE, COLUMN, :bigint)
  end
end
