# frozen_string_literal: true

class CreateSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  INDEX_NAME = 'i_policy_dismissals_on_merge_request_id_and_security_policy_id'

  def up
    # Factory: /ee/spec/factories/security/policy_dismissal.rb
    create_table :security_policy_dismissals do |t| # rubocop:disable Migration/EnsureFactoryForTable -- reason above
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :merge_request_id, null: false
      t.bigint :security_policy_id, null: false
      t.bigint :user_id, null: true
      t.text :security_findings_uuids, array: true, default: [], null: false

      t.index [:merge_request_id, :security_policy_id], unique: true, name: INDEX_NAME
      t.index :project_id
      t.index :security_policy_id
      t.index :user_id
    end
  end

  def down
    drop_table :security_policy_dismissals
  end
end
