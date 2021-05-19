# frozen_string_literal: true

class CreateStatusCheckResponsesTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table :status_check_responses do |t|
      t.bigint :merge_request_id, null: false
      t.bigint :external_approval_rule_id, null: false
    end

    add_index :status_check_responses, :merge_request_id
    add_index :status_check_responses, :external_approval_rule_id
  end

  def down
    drop_table :status_check_responses
  end
end
