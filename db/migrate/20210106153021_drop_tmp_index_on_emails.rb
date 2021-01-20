# frozen_string_literal: true

class DropTmpIndexOnEmails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  EMAIL_INDEX_NAME = 'tmp_index_for_email_unconfirmation_migration'

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('WrongfullyConfirmedEmailUnconfirmer')

    remove_concurrent_index_by_name(:emails, EMAIL_INDEX_NAME)
  end

  def down
    add_concurrent_index(:emails, :id, where: 'confirmed_at IS NOT NULL', name: EMAIL_INDEX_NAME)
  end
end
