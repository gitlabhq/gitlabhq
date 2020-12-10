# frozen_string_literal: true

class Vulnerabilities::FindingReportsComparerEntity < Grape::Entity
  include RequestAwareEntity

  expose :base_report_created_at
  expose :base_report_out_of_date
  expose :head_report_created_at
  expose :added, using: Vulnerabilities::FindingEntity
  expose :fixed, using: Vulnerabilities::FindingEntity
  expose :existing, using: Vulnerabilities::FindingEntity
end
