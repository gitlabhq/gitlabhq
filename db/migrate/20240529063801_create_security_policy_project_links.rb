# frozen_string_literal: true

class CreateSecurityPolicyProjectLinks < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  INDEX_NAME = 'index_security_policy_project_links_on_project_and_policy'

  def up
    create_table :security_policy_project_links do |t|
      t.bigint :project_id, null: false, index: true
      t.bigint :security_policy_id, null: false

      t.index [:security_policy_id, :project_id], unique: true, name: INDEX_NAME
    end
  end

  def down
    drop_table :security_policy_project_links
  end
end
