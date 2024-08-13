# frozen_string_literal: true

class PrepareCiPipelinesProjectIdCheckConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  CONSTRAINT_NAME = 'check_2ba2a044b9'

  def up
    prepare_async_check_constraint_validation :ci_pipelines, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :ci_pipelines, name: CONSTRAINT_NAME
  end
end
