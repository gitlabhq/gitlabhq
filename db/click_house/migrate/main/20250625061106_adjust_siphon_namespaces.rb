# frozen_string_literal: true

class AdjustSiphonNamespaces < ClickHouse::Migration
  def up
    execute "ALTER TABLE siphon_namespaces DROP COLUMN IF EXISTS description_html"

    execute "ALTER TABLE siphon_namespaces MODIFY COLUMN organization_id Int64"
  end

  def down
    execute "ALTER TABLE siphon_namespaces ADD COLUMN IF NOT EXISTS description_html Nullable(String)"

    execute "ALTER TABLE siphon_namespaces MODIFY COLUMN organization_id Nullable(Int64)"
  end
end
