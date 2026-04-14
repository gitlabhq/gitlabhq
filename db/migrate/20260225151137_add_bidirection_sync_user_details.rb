# frozen_string_literal: true

class AddBidirectionSyncUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  TABLE = :user_details
  OLD_COLUMN = :organization
  NEW_COLUMN = :company
  TRIGGER_NAME = 'trigger_c48e4298f362'

  def up
    check_trigger_permissions!(TABLE)

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
  end

  def down
    check_trigger_permissions!(TABLE)

    install_rename_triggers(TABLE, OLD_COLUMN, NEW_COLUMN, trigger_name: TRIGGER_NAME)
  end
end
