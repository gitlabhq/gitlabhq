# frozen_string_literal: true

class CreateCiHostedRunners < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table :ci_hosted_runners, id: false do |t|
      t.bigint :runner_id, null: false, default: nil, primary_key: true
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.foreign_key :instance_type_ci_runners_e59bb2812d, column: :runner_id, on_delete: :cascade
    end
  end
end
