# frozen_string_literal: true

class ReplaceCiTriggerRequestsIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_trigger_requests, [:trigger_id, :id], order: { id: :desc }

    # Some installations have legacy, duplicate indexes on
    # ci_trigger_requests.trigger_id. Rails won't drop them without an
    # explicit name: https://gitlab.com/gitlab-org/gitlab/issues/34818
    old_index_names.each do |name|
      remove_concurrent_index :ci_trigger_requests, [:trigger_id], name: name
    end
  end

  def down
    add_concurrent_index :ci_trigger_requests, [:trigger_id]

    remove_concurrent_index :ci_trigger_requests, [:trigger_id, :id], order: { id: :desc }
  end

  private

  def old_index_names
    indexes(:ci_trigger_requests).select { |i| i.columns == ['trigger_id'] }.map(&:name)
  end
end
