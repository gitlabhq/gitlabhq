# frozen_string_literal: true

class WorkItem < Issue
  self.table_name = 'issues'
  self.inheritance_column = :_type_disabled

  def noteable_target_type_name
    'issue'
  end

  private

  def record_create_action
    super

    Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter.track_work_item_created_action(author: author)
  end
end
