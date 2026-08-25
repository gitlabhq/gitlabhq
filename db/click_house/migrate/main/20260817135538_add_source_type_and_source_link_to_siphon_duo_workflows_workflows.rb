# frozen_string_literal: true

class AddSourceTypeAndSourceLinkToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute "ALTER TABLE siphon_duo_workflows_workflows ADD COLUMN IF NOT EXISTS source_type Nullable(Int16)"
    execute "ALTER TABLE siphon_duo_workflows_workflows ADD COLUMN IF NOT EXISTS source_link Nullable(String)"
  end

  def down
    execute "ALTER TABLE siphon_duo_workflows_workflows DROP COLUMN IF EXISTS source_type"
    execute "ALTER TABLE siphon_duo_workflows_workflows DROP COLUMN IF EXISTS source_link"
  end
end
