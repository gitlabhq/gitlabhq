# frozen_string_literal: true

class ValidateEmailsUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_emails_user_id'

  def up
    validate_foreign_key :emails, :user_id, name: CONSTRAINT_NAME
  end

  def down
    # no op
  end
end
