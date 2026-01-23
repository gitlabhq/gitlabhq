# frozen_string_literal: true

class PrepareUserAgentDetailsOrganizationIdNotNullValidation < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  CONSTRAINT_NAME = 'check_17a3a18e31'

  def up
    prepare_async_check_constraint_validation :user_agent_details, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :user_agent_details, name: CONSTRAINT_NAME
  end
end
