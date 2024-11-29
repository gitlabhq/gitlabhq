# frozen_string_literal: true

class AsyncValidationForCiPipelinesFks < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    return unless Gitlab.com_except_jh?

    prepare_partitioned_async_foreign_key_validation(:p_ci_builds, name: :fk_rails_494e57ee78_p)
    prepare_partitioned_async_foreign_key_validation(:p_ci_pipeline_variables, name: :fk_rails_507416c33a_p)
  end

  def down
    return unless Gitlab.com_except_jh?

    unprepare_partitioned_async_foreign_key_validation(:p_ci_builds, name: :fk_rails_494e57ee78_p)
    unprepare_partitioned_async_foreign_key_validation(:p_ci_pipeline_variables, name: :fk_rails_507416c33a_p)
  end
end
