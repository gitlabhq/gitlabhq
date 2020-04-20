# frozen_string_literal: true
#
class ValidateU2fRegistrationsUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_u2f_registrations_user_id'

  def up
    validate_foreign_key :u2f_registrations, :user_id, name: CONSTRAINT_NAME
  end

  def down
    # no op
  end
end
