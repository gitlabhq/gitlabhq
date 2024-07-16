# frozen_string_literal: true

class FinalizeConvertCreditCardValidationDataToHashes < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'ConvertCreditCardValidationDataToHashes',
      table_name: :user_credit_card_validations,
      column_name: :user_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
