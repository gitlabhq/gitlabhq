# frozen_string_literal: true

class DropTempIndexOnProjectsOnIdAndRunnersTokenEncrypted < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TEMP_INDEX_NAME = 'tmp_index_projects_on_id_and_runners_token_encrypted'

  def up
    finalize_background_migration 'ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects'

    remove_concurrent_index_by_name :projects, TEMP_INDEX_NAME
  end

  def down
    add_concurrent_index :projects,
                         [:id, :runners_token_encrypted],
                         where: "runners_token_encrypted IS NOT NULL",
                         unique: false,
                         name: TEMP_INDEX_NAME
  end
end
