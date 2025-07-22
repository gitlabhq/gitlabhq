# frozen_string_literal: true

class ValidateTargetProjectIdComplianceViolations < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  FK_NAME = :fk_492a40969e
  def up
    prepare_async_foreign_key_validation :merge_requests_compliance_violations, :target_project_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :merge_requests_compliance_violations, :target_project_id, name: FK_NAME
  end
end
