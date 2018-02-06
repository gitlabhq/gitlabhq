# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveDuplicateMrEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  class Event < ActiveRecord::Base
    self.table_name = 'events'
  end

  def up
    base_condition = "action = 1 AND target_type = 'MergeRequest' AND created_at > '2017-08-13'"
    Event.select('target_id, count(*)')
      .where(base_condition)
      .group('target_id').having('count(*) > 1').each do |event|
      duplicates = Event.where("#{base_condition} AND target_id = #{event.target_id}").pluck(:id)
      duplicates.shift

      Event.where(id: duplicates).delete_all
    end
  end

  def down
  end
end
