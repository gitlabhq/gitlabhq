# frozen_string_literal: true

class SyncRelativePositioningNamespaceIdToWorkItemPositions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.3'

  TRIGGER_FUNCTION_NAME = 'sync_work_item_positions_from_issues'

  # Replaces the sync trigger function body so it also populates
  # relative_positioning_namespace_id. The CASE mirrors Namespace#work_item_positioning_root:
  # the project namespace itself when its parent is a user namespace, otherwise the root
  # ancestor (traversal_ids[1]). Only the function body changes; the trigger on `issues` is
  # untouched, so this does not lock the issues table.
  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        INSERT INTO work_item_positions (
          work_item_id,
          namespace_id,
          relative_positioning_namespace_id,
          relative_position,
          created_at,
          updated_at
        )
        VALUES (
          NEW.id,
          NEW.namespace_id,
          (
            SELECT CASE
              WHEN p.type = 'User' OR p.type IS NULL THEN n.id
              ELSE COALESCE(n.traversal_ids[1], n.id)
            END
            FROM namespaces n
            LEFT JOIN namespaces p ON p.id = n.parent_id
            WHERE n.id = NEW.namespace_id
          ),
          NEW.relative_position,
          NOW(),
          NOW()
        )
        ON CONFLICT (work_item_id)
        DO UPDATE SET
          relative_position = EXCLUDED.relative_position,
          namespace_id = EXCLUDED.namespace_id,
          relative_positioning_namespace_id = EXCLUDED.relative_positioning_namespace_id,
          updated_at = NOW();
        RETURN NULL;
      SQL
    end
  end

  def down
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        INSERT INTO work_item_positions (
          work_item_id,
          namespace_id,
          relative_position,
          created_at,
          updated_at
        )
        VALUES (
          NEW.id,
          NEW.namespace_id,
          NEW.relative_position,
          NOW(),
          NOW()
        )
        ON CONFLICT (work_item_id)
        DO UPDATE SET
          relative_position = EXCLUDED.relative_position,
          namespace_id = EXCLUDED.namespace_id,
          updated_at = NOW();
        RETURN NULL;
      SQL
    end
  end
end
