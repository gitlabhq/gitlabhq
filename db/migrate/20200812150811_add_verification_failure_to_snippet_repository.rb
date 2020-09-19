# frozen_string_literal: true

class AddVerificationFailureToSnippetRepository < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'snippet_repositories_verification_failure_text_limit'

  def up
    add_text_limit :snippet_repositories, :verification_failure, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint(:snippet_repositories, CONSTRAINT_NAME)
  end
end
