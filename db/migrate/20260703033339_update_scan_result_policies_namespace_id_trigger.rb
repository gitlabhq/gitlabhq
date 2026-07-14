# frozen_string_literal: true

class UpdateScanResultPoliciesNamespaceIdTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.2'

  FUNCTION_NAME = 'trigger_b83b7e51e2f5'

  def up
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        IF NEW."namespace_id" IS NULL AND NEW."project_id" IS NULL THEN
          SELECT "namespace_id"
          INTO NEW."namespace_id"
          FROM "security_orchestration_policy_configurations"
          WHERE "security_orchestration_policy_configurations"."id" = NEW."security_orchestration_policy_configuration_id";
        END IF;

        RETURN NEW;
      SQL
    end
  end

  def down
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        IF NEW."namespace_id" IS NULL THEN
          SELECT "namespace_id"
          INTO NEW."namespace_id"
          FROM "security_orchestration_policy_configurations"
          WHERE "security_orchestration_policy_configurations"."id" = NEW."security_orchestration_policy_configuration_id";
        END IF;

        RETURN NEW;
      SQL
    end
  end
end
