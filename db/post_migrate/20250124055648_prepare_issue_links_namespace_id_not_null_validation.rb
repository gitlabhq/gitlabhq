# frozen_string_literal: true

class PrepareIssueLinksNamespaceIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_c32f659c75

  def up
    prepare_async_check_constraint_validation :issue_links, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :issue_links, name: CONSTRAINT_NAME
  end
end
