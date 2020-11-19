# frozen_string_literal: true

class RemoveNotNullConstraintOnFramework < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  GDPR_FRAMEWORK_ID = 1

  disable_ddl_transaction!

  class TmpComplianceProjectFrameworkSetting < ActiveRecord::Base
    self.table_name = 'project_compliance_framework_settings'
    self.primary_key = :project_id

    include EachBatch
  end

  def up
    change_column_null :project_compliance_framework_settings, :framework, true
  end

  def down
    # Custom frameworks cannot be rolled back easily since we don't have enum for them.
    # To make the database consistent, we mark them as GDPR framework.
    # Note: framework customization will be implemented in the next 1-3 releases so data
    # corruption due to the rollback is unlikely.
    TmpComplianceProjectFrameworkSetting.each_batch(of: 100) do |query|
      query.where(framework: nil).update_all(framework: GDPR_FRAMEWORK_ID)
    end

    change_column_null :project_compliance_framework_settings, :framework, false
  end
end
