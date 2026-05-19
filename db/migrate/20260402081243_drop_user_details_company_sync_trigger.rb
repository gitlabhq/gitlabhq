# frozen_string_literal: true

class DropUserDetailsCompanySyncTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!

  milestone '19.0'

  TABLE = :user_details
  OLD_COLUMN = :organization
  NEW_COLUMN = :company
  TRIGGER_NAME = :trigger_c48e4298f362

  def up
    drop_trigger(TABLE, TRIGGER_NAME)
    drop_function(TRIGGER_NAME)
  end

  def down
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_NAME}()
      RETURNS trigger AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          IF NEW.#{NEW_COLUMN} IS NOT NULL AND NEW.#{NEW_COLUMN} != '' THEN
            NEW.#{OLD_COLUMN} := NEW.#{NEW_COLUMN};
          ELSE
            NEW.#{NEW_COLUMN} := NEW.#{OLD_COLUMN};
          END IF;
        ELSIF TG_OP = 'UPDATE' THEN
          IF OLD.#{NEW_COLUMN} IS DISTINCT FROM NEW.#{NEW_COLUMN} THEN
            NEW.#{OLD_COLUMN} := NEW.#{NEW_COLUMN};
          ELSIF OLD.#{OLD_COLUMN} IS DISTINCT FROM NEW.#{OLD_COLUMN} THEN
            NEW.#{NEW_COLUMN} := NEW.#{OLD_COLUMN};
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_NAME} BEFORE
      INSERT OR UPDATE ON #{TABLE}
      FOR EACH ROW EXECUTE FUNCTION #{TRIGGER_NAME}()
    SQL
  end
end
