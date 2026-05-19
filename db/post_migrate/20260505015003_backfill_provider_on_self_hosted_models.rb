# frozen_string_literal: true

class BackfillProviderOnSelfHostedModels < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting
  milestone '19.0'

  def up
    # provider values:
    # 0 = api
    # 1 = bedrock
    # 2 = vertex_ai

    execute("UPDATE ai_self_hosted_models SET provider = 1 WHERE identifier LIKE 'bedrock/%'")
    execute("UPDATE ai_self_hosted_models SET provider = 2 WHERE identifier LIKE 'vertex_ai/%'")
  end

  def down
    # no-op

    # Irreversible: reverting the migration would re-introduce incorrect data.
  end
end
