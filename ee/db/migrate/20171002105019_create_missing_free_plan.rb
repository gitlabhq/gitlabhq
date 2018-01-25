class CreateMissingFreePlan < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class Plan < ActiveRecord::Base
    self.table_name = 'plans'
  end

  def up
    Plan.create!(name: 'free', title: 'Free')
  end

  def down
    Plan.find_by(name: 'free')&.destroy!
  end
end
