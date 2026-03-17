# frozen_string_literal: true

class AddDependentIssueCheckBeforeDeletingWorkItemCustomType < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  ISSUES_FUNCTION = 'exists_issues_for_work_item_custom_type'
  TRIGGER_NAME = 'prevent_custom_work_item_type_deletion_if_referenced'
  TRIGGER_FUNCTION = 'work_item_custom_types_integrity_children_check'

  milestone '18.10'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{ISSUES_FUNCTION}(work_item_type_id bigint)
      RETURNS boolean
      LANGUAGE plpgsql
      STABLE
      PARALLEL SAFE
      COST 1
      AS $$
      BEGIN
        PERFORM 1
        FROM "issues"
        WHERE "issues"."work_item_type_id" = $1
        LIMIT 1;

        RETURN FOUND;
      END;
      $$;
    SQL

    create_trigger_function(TRIGGER_FUNCTION) do
      <<~SQL
        IF #{ISSUES_FUNCTION}(OLD.id) THEN
          RAISE EXCEPTION
            'Cannot delete work_item_custom_type %, referenced in issues',
            OLD.id;
        END IF;

        RETURN OLD;
      SQL
    end

    create_trigger(:work_item_custom_types, TRIGGER_NAME, TRIGGER_FUNCTION, fires: 'BEFORE DELETE')
  end

  def down
    drop_trigger(:work_item_custom_types, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION)

    execute(<<~SQL)
      DROP FUNCTION IF EXISTS #{ISSUES_FUNCTION}
    SQL
  end
end
