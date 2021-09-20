# frozen_string_literal: true

class CreateProjectTopics < ActiveRecord::Migration[6.1]
  def change
    create_table :project_topics do |t|
      t.bigint :project_id, null: false
      t.bigint :topic_id, null: false

      t.index :project_id
      t.index :topic_id
      t.index [:project_id, :topic_id], unique: true

      t.timestamps_with_timezone
    end
  end
end
