# frozen_string_literal: true

class UpsertBaseWorkItemTypes < ActiveRecord::Migration[6.1]
  module WorkItem
    class Type < ActiveRecord::Base
      self.table_name = 'work_item_types'

      enum base_type: {
        issue: 0,
        incident: 1,
        test_case: 2,
        requirement: 3
      }
    end
  end

  def up
    # upsert default types
    WorkItem::Type.find_or_create_by(name: 'Issue', namespace_id: nil, base_type: :issue, icon_name: 'issue-type-issue')
    WorkItem::Type.find_or_create_by(name: 'Incident', namespace_id: nil, base_type: :incident, icon_name: 'issue-type-incident')
    WorkItem::Type.find_or_create_by(name: 'Test Case', namespace_id: nil, base_type: :test_case, icon_name: 'issue-type-test-case')
    WorkItem::Type.find_or_create_by(name: 'Requirement', namespace_id: nil, base_type: :requirement, icon_name: 'issue-type-requirements')
  end

  def down
    # We expect this table to be empty at the point of the up migration,
    # however there is a remote possibility that issues could already be
    # using one of these types, with a tight foreign constraint.
    # Therefore we will not attempt to remove any data.
  end
end
