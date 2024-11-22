# frozen_string_literal: true

class MoveAllReadyZoektIndicesToPending < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  milestone '17.7'

  def up
    # Since this was done manually for dotcom, this migration should only
    # be run for self managed customers that are EE
    return if ::Gitlab.com? || !::Gitlab.ee?

    Search::Zoekt::Index.ready.each_batch do |batch|
      batch.update_all(state: :pending)
    end
  end

  def down
    # no-op
  end
end
