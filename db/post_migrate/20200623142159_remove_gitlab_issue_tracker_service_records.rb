# frozen_string_literal: true

class RemoveGitlabIssueTrackerServiceRecords < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  BATCH_SIZE = 5000

  disable_ddl_transaction!

  class Service < ActiveRecord::Base
    include EachBatch

    self.table_name = 'services'

    def self.gitlab_issue_tracker_service
      where(type: 'GitlabIssueTrackerService')
    end
  end

  def up
    Service.each_batch(of: BATCH_SIZE) do |services|
      services.gitlab_issue_tracker_service.delete_all
    end
  end

  def down
    # no-op
  end
end
