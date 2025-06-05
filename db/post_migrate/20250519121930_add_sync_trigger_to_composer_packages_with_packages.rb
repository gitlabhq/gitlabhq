# frozen_string_literal: true

class AddSyncTriggerToComposerPackagesWithPackages < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  include Gitlab::Database::SchemaHelpers

  TRIGGER_FUNCTION_NAME = 'sync_packages_composer_with_packages'
  TRIGGER_NAME = 'trigger_sync_packages_composer_with_packages'
  PACKAGES_TABLE = 'packages_packages'
  PACKAGES_COMPOSER_TABLE = 'packages_composer_packages'
  COMPOSER_PACKAGE_TYPE = 6

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        IF (COALESCE(NEW.package_type, OLD.package_type) = #{COMPOSER_PACKAGE_TYPE}) THEN
          IF (TG_OP = 'INSERT') THEN
            INSERT INTO "#{PACKAGES_COMPOSER_TABLE}" (id, project_id, created_at, updated_at, name, version, creator_id, status, last_downloaded_at, status_message)
              VALUES (NEW.id, NEW.project_id, NEW.created_at, NEW.updated_at, NEW.name, NEW.version, NEW.creator_id, NEW.status, NEW.last_downloaded_at, NEW.status_message);
          ELSIF (TG_OP = 'UPDATE') THEN
            UPDATE "#{PACKAGES_COMPOSER_TABLE}"
                SET project_id = NEW.project_id,
                    updated_at = NEW.updated_at,
                    name = NEW.name,
                    version = NEW.version,
                    creator_id = NEW.creator_id,
                    status = NEW.status,
                    last_downloaded_at = NEW.last_downloaded_at,
                    status_message = NEW.status_message
                WHERE id = OLD.id;
          ELSIF (TG_OP = 'DELETE') THEN
            DELETE FROM "#{PACKAGES_COMPOSER_TABLE}" WHERE id = OLD.id;
          END IF;
        END IF;
        RETURN NULL;
      SQL
    end

    create_trigger(
      PACKAGES_TABLE, TRIGGER_NAME, TRIGGER_FUNCTION_NAME, fires: 'AFTER INSERT OR UPDATE OR DELETE'
    )
  end

  def down
    drop_trigger(PACKAGES_TABLE, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
