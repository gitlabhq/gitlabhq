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
    # https://github.com/rails/rails/issues/35493
    VulnerabilitiesFeedback.where('issue_id IS NOT NULL').each_batch do |relation|
      timestamp = Time.now
      values = relation
        .joins("JOIN vulnerability_occurrences vo ON vo.project_id = vulnerability_feedback.project_id AND vo.report_type = vulnerability_feedback.category AND encode(vo.project_fingerprint, 'hex') = vulnerability_feedback.project_fingerprint")
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

      next if values.empty?

      VulnerabilitiesIssueLink.insert_all(
        values,
        returning: false,
        unique_by: %i[vulnerability_id issue_id]
      )
    end
  end

  def down
  end
end
