# frozen_string_literal: true

class AddRelativePositioningNamespaceIdToWorkItemPositions < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  # Nullable column with no default is an instant, metadata-only change (Postgres 11+),
  # safe in a regular migration even on a large table.
  #
  # Holds the "positioning root" (Namespace#work_item_positioning_root): the project
  # namespace for projects under a personal namespace, the root ancestor otherwise.
  # Populated for new/changed rows by the sync_work_item_positions_from_issues trigger;
  # existing rows are backfilled in a follow-up MR.
  def change
    add_column :work_item_positions, :relative_positioning_namespace_id, :bigint
  end
end
