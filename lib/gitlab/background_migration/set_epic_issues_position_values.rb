module Gitlab
  module BackgroundMigration
    class SetEpicIssuesPositionValues
      class Epic < ActiveRecord::Base
        self.table_name = 'epics'
      end

      class EpicIssue < ActiveRecord::Base
        self.table_name = 'epic_issues'
      end

      def perform(start_id, end_id)
        epic_issues =  EpicIssue.where(epic_id: start_id..end_id).order('epic_id, id').group_by { |e| e['epic_id'] }
        return if epic_issues.empty?
        update = []

        epic_issues.each do |epic_id, issues|
          issues.each_with_index do |epic_issue, index|
            update << "WHEN id = #{epic_issue['id']} THEN #{index + 1}"
          end
        end

        EpicIssue.where(epic_id: start_id..end_id).update_all("position = CASE #{update.join(' ')} END")
      end
    end
  end
end
