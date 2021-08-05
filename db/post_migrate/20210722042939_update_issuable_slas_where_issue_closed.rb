# frozen_string_literal: true

class UpdateIssuableSlasWhereIssueClosed < ActiveRecord::Migration[6.1]
  ISSUE_CLOSED_STATUS = 2

  class IssuableSla < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issuable_slas'

    belongs_to :issue, class_name: 'Issue'
  end

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'

    has_one :issuable_sla, class_name: 'IssuableSla'
  end

  def up
    IssuableSla.each_batch(of: 50) do |relation|
      relation.joins(:issue)
              .where(issues: { state_id: ISSUE_CLOSED_STATUS } )
              .update_all(issuable_closed: true)
    end
  end

  def down
    # no-op
  end
end
