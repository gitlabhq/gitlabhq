# frozen_string_literal: true

class CreateBaseWorkItemTypes < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  module WorkItem
    class Type < ActiveRecord::Base
      self.table_name = 'work_item_types'

      enum base_type: {
        issue:       0,
        incident:    1,
        test_case:   2,
        requirement: 3
      }

      validates :name, uniqueness: { case_sensitive: false, scope: [:namespace_id] }
    end
  end

  def up
    # create default types
    WorkItem::Type.create(name: 'Issue', namespace_id: nil, base_type: :issue, icon_name: 'issue-type-issue')
    WorkItem::Type.create(name: 'Incident', namespace_id: nil, base_type: :incident, icon_name: 'issue-type-incident')
    WorkItem::Type.create(name: 'Test Case', namespace_id: nil, base_type: :test_case, icon_name: 'issue-type-test-case')
    WorkItem::Type.create(name: 'Requirement', namespace_id: nil, base_type: :requirement, icon_name: 'issue-type-requirements')
  end

  def down
    # We expect this table to be empty at the point of the up migration,
    # however there is a remote possibility that issues could already be
    # using one of these types, with a tight foreign constraint.
    # Therefore we will not attempt to remove any data.
  end
end
