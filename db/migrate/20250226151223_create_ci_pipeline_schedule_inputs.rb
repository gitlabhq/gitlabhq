# frozen_string_literal: true

class CreateCiPipelineScheduleInputs < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table :ci_pipeline_schedule_inputs do |t|
      t.belongs_to :pipeline_schedule, null: false,
        foreign_key: { on_delete: :cascade, to_table: :ci_pipeline_schedules }
      t.belongs_to :project, null: false
      t.text :name, null: false, limit: 255
      t.jsonb :value
    end
  end
end
