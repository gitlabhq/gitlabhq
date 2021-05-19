# frozen_string_literal: true

# rubocop: disable Style/Documentation
class Gitlab::BackgroundMigration::DropInvalidVulnerabilities
  # rubocop: disable Gitlab/NamespacedClass
  class Vulnerability < ActiveRecord::Base
    self.table_name = "vulnerabilities"
    has_many :findings, class_name: 'VulnerabilitiesFinding', inverse_of: :vulnerability
  end

  class VulnerabilitiesFinding < ActiveRecord::Base
    self.table_name = "vulnerability_occurrences"
    belongs_to :vulnerability, class_name: 'Vulnerability', inverse_of: :findings, foreign_key: 'vulnerability_id'
  end
  # rubocop: enable Gitlab/NamespacedClass

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(start_id, end_id)
    Vulnerability
      .where(id: start_id..end_id)
      .left_joins(:findings)
      .where(vulnerability_occurrences: { vulnerability_id: nil })
      .delete_all

    mark_job_as_succeeded(start_id, end_id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def mark_job_as_succeeded(*arguments)
    Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
      'DropInvalidVulnerabilities',
      arguments
    )
  end
end
