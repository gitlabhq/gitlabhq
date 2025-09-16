# frozen_string_literal: true

class ValidateCiSourcesPipelinesNotNullShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    validate_not_null_constraint :ci_sources_pipelines, :project_id, constraint_name: :check_5a76e457e6
  end

  def down
    # noop
  end
end
