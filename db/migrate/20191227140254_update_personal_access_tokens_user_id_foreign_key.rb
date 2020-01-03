# frozen_string_literal: true

class UpdatePersonalAccessTokensUserIdForeignKey < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_personal_access_tokens_user_id'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:personal_access_tokens, :users, column: :user_id, on_delete: :cascade, name: CONSTRAINT_NAME)
    remove_foreign_key_if_exists(:personal_access_tokens, column: :user_id, on_delete: nil)
  end

  def down
    add_concurrent_foreign_key(:personal_access_tokens, :users, column: :user_id, on_delete: nil)
    remove_foreign_key_if_exists(:personal_access_tokens, column: :user_id, on_delete: :cascade, name: CONSTRAINT_NAME)
  end
end
