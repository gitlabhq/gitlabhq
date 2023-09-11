# frozen_string_literal: true

class CreateGroupsVisitsTables < Gitlab::Database::Migration[2.1]
  def up
    create_table :groups_visits, primary_key: [:id, :visited_at],
      options: 'PARTITION BY RANGE (visited_at)' do |t|
      t.bigserial :id, null: false
      t.bigint :entity_id, null: false, index: true
      t.bigint :user_id, null: false
      t.datetime_with_timezone :visited_at, null: false
    end

    add_index(:groups_visits, [:user_id, :entity_id, :visited_at])
  end

  def down
    drop_table :groups_visits
  end
end
