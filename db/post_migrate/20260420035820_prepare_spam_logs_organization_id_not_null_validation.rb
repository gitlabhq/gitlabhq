# frozen_string_literal: true

class PrepareSpamLogsOrganizationIdNotNullValidation < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  CONSTRAINT_NAME = 'check_0c0873a24a'

  def up
    prepare_async_check_constraint_validation :spam_logs, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :spam_logs, name: CONSTRAINT_NAME
  end
end
