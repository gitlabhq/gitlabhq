# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreatePlans < ActiveRecord::Migration
  DOWNTIME = false

  class Plan < ActiveRecord::Base
    self.table_name = 'plans'
  end

  def up
    create_table :plans do |t|
      t.timestamps_with_timezone null: false
      t.string :name, index: true
      t.string :title
    end

    %w[early_adopter bronze silver gold].each do |plan|
      Plan.create!(name: plan, title: plan.titleize)
    end
  end

  def down
    drop_table :plans
  end
end
