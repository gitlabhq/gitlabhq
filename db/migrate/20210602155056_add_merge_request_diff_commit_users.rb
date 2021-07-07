# frozen_string_literal: true

class AddMergeRequestDiffCommitUsers < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    create_table_with_constraints :merge_request_diff_commit_users, id: :bigint do |t|
      t.text :name
      t.text :email

      t.text_limit :name, 512
      t.text_limit :email, 512

      t.index [:name, :email], unique: true
    end

    # Names or Emails can be optional, so in some cases one of these may be
    # null. But if both are NULL/empty, no row should exist in this table.
    add_check_constraint(
      :merge_request_diff_commit_users,
      "(COALESCE(name, '') != '') OR (COALESCE(email, '') != '')",
      :merge_request_diff_commit_users_name_or_email_existence
    )
  end

  def down
    drop_table :merge_request_diff_commit_users
  end
end
