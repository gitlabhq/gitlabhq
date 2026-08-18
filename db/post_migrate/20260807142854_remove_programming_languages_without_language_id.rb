# frozen_string_literal: true

class RemoveProgrammingLanguagesWithoutLanguageId < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_local
  disable_ddl_transaction!

  def up
    # The related BBM has completed on GitLab.com, so this cleanup runs there now to unblock the Cells migration.
    # Self-managed instances will be cleaned up in a future milestone after the BBM is finalized.
    return unless Gitlab.com_except_jh?

    programming_languages = define_batchable_model('programming_languages')

    programming_languages.where(language_id: nil).each_batch do |batch|
      batch.delete_all
    end
  end

  def down
    # No-op because DetectRepositoryLanguagesWorker regenerates the deleted data from Gitaly.
  end
end
