class SetEpicIssuePositionValues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    self.table_name = 'epics'
  end

  class EpicIssue < ActiveRecord::Base
    self.table_name = 'epic_issues'
  end

  def up
    epic_issues = select_all('SELECT id, epic_id FROM epic_issues ORDER by epic_id, id')
      .group_by { |e| e['epic_id'] }

    epic_issues.each do |epic_id, epic_issues|
      epic_issues.each_with_index do |epic_issue, index|
        execute("UPDATE epic_issues SET position = #{index + 1} WHERE id = #{epic_issue['id']}")
      end
    end
  end

  def down
    execute('UPDATE epic_issues SET position = 1')
  end
end
