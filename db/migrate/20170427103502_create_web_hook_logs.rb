# rubocop:disable all
class CreateWebHookLogs < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :web_hook_logs do |t|
      t.references :web_hook, null: false, index: true, foreign_key: { on_delete: :cascade }

      t.string :trigger
      t.string :url
      t.text :request_headers
      t.text :request_data
      t.text :response_headers
      t.text :response_body
      t.string :response_status
      t.float :execution_duration
      t.string :internal_error_message

      t.timestamps null: false
    end
  end
end
