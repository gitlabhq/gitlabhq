# frozen_string_literal: true

class CreateMissingVulnerabilitiesIssueLinks < ActiveRecord::Migration[6.0]
  class VulnerabilitiesFeedback < ActiveRecord::Base
    include EachBatch
    self.table_name = 'vulnerability_feedback'
  end

  class VulnerabilitiesIssueLink < ActiveRecord::Base
    self.table_name = 'vulnerability_issue_links'
    LINK_TYPE_CREATED = 2
  end

  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    VulnerabilitiesFeedback.where.not(issue_id: nil).each_batch do |relation|
      timestamp = Time.now
      issue_links = relation
        .joins("JOIN vulnerability_occurrences vo ON vo.project_id = vulnerability_feedback.project_id AND vo.report_type = vulnerability_feedback.category AND encode(vo.project_fingerprint, 'hex') = vulnerability_feedback.project_fingerprint")
        .where.not('vo.vulnerability_id' => nil)
        .pluck(:vulnerability_id, :issue_id)
        .map do |v_id, i_id|
          {
            vulnerability_id: v_id,
            issue_id: i_id,
            link_type: VulnerabilitiesIssueLink::LINK_TYPE_CREATED,
            created_at: timestamp,
            updated_at: timestamp
          }
        end

      next if issue_links.empty?

      VulnerabilitiesIssueLink.insert_all(
        issue_links,
        returning: false
      )
    end
  end

  def down
  end
end
