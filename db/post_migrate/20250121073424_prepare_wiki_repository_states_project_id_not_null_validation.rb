# frozen_string_literal: true

class PrepareWikiRepositoryStatesProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_69aed91301

  def up
    prepare_async_check_constraint_validation :wiki_repository_states, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :wiki_repository_states, name: CONSTRAINT_NAME
  end
end
