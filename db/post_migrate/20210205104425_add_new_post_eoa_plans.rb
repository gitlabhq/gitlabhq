# frozen_string_literal: true

class AddNewPostEoaPlans < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute "INSERT INTO plans (name, title, created_at, updated_at) VALUES ('premium', 'Premium (Formerly Silver)', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    execute "INSERT INTO plans (name, title, created_at, updated_at) VALUES ('ultimate', 'Ultimate (Formerly Gold)', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
  end

  def down
    execute "DELETE FROM plans WHERE name IN ('premium', 'ultimate')"
  end
end
