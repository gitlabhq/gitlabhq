# frozen_string_literal: true

class RemoveNullConstraintFromSecurityFindings < ActiveRecord::Migration[6.1]
  def up
    change_column_null :security_findings, :project_fingerprint, true
  end

  def down
    # no-op, it can not be reverted due to existing records that might not be valid
  end
end
