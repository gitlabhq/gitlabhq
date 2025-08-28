# frozen_string_literal: true

class AddRawSourceCodeExtractToSecurityFindingTokenStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :security_finding_token_statuses, :raw_source_code_extract, :text, if_not_exists: true
    end

    add_text_limit(
      :security_finding_token_statuses,
      :raw_source_code_extract,
      2048,
      constraint_name: "raw_source_code_extract_not_longer_than_2048"
    )
  end

  def down
    with_lock_retries do
      remove_column :security_finding_token_statuses, :raw_source_code_extract, :text
    end
  end
end
