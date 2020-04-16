# frozen_string_literal: true

# rubocop: disable Migration/AddConcurrentForeignKey
class AddU2fRegistrationsUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_u2f_registrations_user_id'

  def up
    with_lock_retries do
      add_foreign_key(:u2f_registrations, :users, on_delete: :cascade, validate: false, name: CONSTRAINT_NAME)
      remove_foreign_key_if_exists(:u2f_registrations, column: :user_id, on_delete: nil)
    end
  end

  def down
    fk_exists = foreign_key_exists?(:u2f_registrations, :users, column: :user_id, on_delete: nil)

    unless fk_exists
      with_lock_retries do
        add_foreign_key(:u2f_registrations, :users, column: :user_id, validate: false)
      end
    end

    remove_foreign_key_if_exists(:u2f_registrations, column: :user_id, name: CONSTRAINT_NAME)

    fk_name = concurrent_foreign_key_name(:u2f_registrations, :user_id, prefix: 'fk_rails_')
    validate_foreign_key(:u2f_registrations, :user_id, name: fk_name)
  end
end
