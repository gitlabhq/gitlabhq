# frozen_string_literal: true

class PrepareEpicUserMentionsGroupIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_4865a37c73

  def up
    prepare_async_check_constraint_validation :epic_user_mentions, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :epic_user_mentions, name: CONSTRAINT_NAME
  end
end
