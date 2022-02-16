# frozen_string_literal: true

class UpdateIntegrationsTriggerTypeNewOnInsertNullSafe < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'integrations_set_type_new'

  def up
    # Update `type_new` dynamically based on `type`, if `type_new` is null
    # and `type` dynamically based on `type_new`, if `type` is null.
    #
    # The old class names are in the format `AbcService`, and the new ones `Integrations::Abc`.
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL.squish
        UPDATE integrations
           SET type_new = COALESCE(NEW.type_new, regexp_replace(NEW.type, '\\A(.+)Service\\Z', 'Integrations::\\1'))
             , type     = COALESCE(NEW.type, regexp_replace(NEW.type_new, '\\AIntegrations::(.+)\\Z', '\\1Service'))
        WHERE integrations.id = NEW.id;
        RETURN NULL;
      SQL
    end
  end

  def down
    # Update `type_new` dynamically based on `type`.
    #
    # The old class names are in the format `AbcService`, and the new ones `Integrations::Abc`.
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        UPDATE integrations SET type_new = regexp_replace(NEW.type, '\\A(.+)Service\\Z', 'Integrations::\\1')
        WHERE integrations.id = NEW.id;
        RETURN NULL;
      SQL
    end
  end
end
