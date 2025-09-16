# frozen_string_literal: true

class PrepareCiSourcesPipelinesProjectIdNotNullValidation < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  CONSTRAINT_NAME = :check_5a76e457e6

  def up
    prepare_async_check_constraint_validation :ci_sources_pipelines, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :ci_sources_pipelines, name: CONSTRAINT_NAME
  end
end
