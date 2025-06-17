# frozen_string_literal: true

class AddSyncTriggerToComposerPackagesWithComposerMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  include Gitlab::Database::SchemaHelpers

  TRIGGER_FUNCTION_NAME = 'sync_packages_composer_with_composer_metadata'
  TRIGGER_NAME = 'trigger_sync_packages_composer_with_composer_metadata'
  COMPOSER_METADATA_TABLE = 'packages_composer_metadata'
  PACKAGES_COMPOSER_TABLE = 'packages_composer_packages'

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME, replace: true) do
      <<~SQL
        UPDATE "#{PACKAGES_COMPOSER_TABLE}"
            SET target_sha = NEW.target_sha,
                composer_json = NEW.composer_json,
                version_cache_sha = NEW.version_cache_sha
            WHERE id = NEW.package_id;
        RETURN NULL;
      SQL
    end

    create_trigger(
      COMPOSER_METADATA_TABLE, TRIGGER_NAME, TRIGGER_FUNCTION_NAME, fires: 'AFTER INSERT OR UPDATE'
    )
  end

  def down
    drop_trigger(COMPOSER_METADATA_TABLE, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
