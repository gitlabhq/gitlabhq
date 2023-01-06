# frozen_string_literal: true

class RemoveCheckConstraintOnChatNamesOnIntegration < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'check_2b0a0d0f0f'

  disable_ddl_transaction!

  def up
    remove_check_constraint(:chat_names, CONSTRAINT_NAME)
  end

  def down
    # noop: rollback would not work as we can have records where `integration_id` IS NULL
  end
end
