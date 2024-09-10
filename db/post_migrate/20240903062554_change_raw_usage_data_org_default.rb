# frozen_string_literal: true

class ChangeRawUsageDataOrgDefault < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.4'

  def change
    change_column_default('raw_usage_data', 'organization_id',
      from: Organizations::Organization::DEFAULT_ORGANIZATION_ID,
      to: nil)
  end
end
