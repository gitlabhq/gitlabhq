# frozen_string_literal: true

class CleanupBackfillIntegrationsEnableSslVerification < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  MIGRATION = 'BackfillIntegrationsEnableSslVerification'

  def up
    finalize_background_migration(MIGRATION)
  end

  def down
    # no-op
  end
end
