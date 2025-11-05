# frozen_string_literal: true

class AddShardingKeyToServiceHooks < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 500

  UPDATE_SQL = <<~SQL
    WITH integration_sharding_keys (web_hook_id, integration_id, project_id, group_id, organization_id) AS (
        %{with_values}
    )
    UPDATE
      web_hooks
    SET
      project_id = integration_sharding_keys.project_id::bigint,
      group_id = integration_sharding_keys.group_id::bigint,
      organization_id = integration_sharding_keys.organization_id::bigint
    FROM
      integration_sharding_keys
    WHERE
      integration_sharding_keys.integration_id = web_hooks.integration_id AND
      web_hooks.id = integration_sharding_keys.web_hook_id
  SQL

  def up
    web_hooks_model = define_batchable_model('web_hooks')
    define_batchable_model('integrations')

    # Join web_hooks with integrations and collect all data in one query
    web_hooks_model
      .joins("INNER JOIN integrations ON web_hooks.integration_id = integrations.id")
      .where.not(integration_id: nil)
      .where(type: 'ServiceHook')
      .each_batch(of: BATCH_SIZE) do |batch|
      data_to_update = batch.pluck(
        'web_hooks.id',
        'web_hooks.integration_id',
        'integrations.project_id',
        'integrations.group_id',
        'integrations.organization_id'
      )

      # Split data into BATCH_SIZE chunks
      data_to_update.each_slice(SUB_BATCH_SIZE) do |sub_batch|
        integration_data = sub_batch

        # Build Arel::Nodes::ValuesList object
        values_sql = build_values_sql(integration_data)
        next if values_sql.blank?

        # Use CTE+UPDATE query to update rows
        execute_update(values_sql)
      end
    end
  end

  def down
    # no op
  end

  private

  def build_values_sql(integration_data)
    return if integration_data.blank?

    values = integration_data.map do |web_hook_id, integration_id, project_id, group_id, organization_id|
      [
        web_hook_id,
        integration_id,
        project_id,
        group_id,
        organization_id
      ]
    end

    Arel::Nodes::ValuesList.new(values).to_sql
  end

  def execute_update(values_sql)
    return if values_sql.blank?

    sql = format(UPDATE_SQL,
      with_values: values_sql)

    connection.execute(sql)
  end
end
