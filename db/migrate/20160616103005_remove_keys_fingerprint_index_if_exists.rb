class RemoveKeysFingerprintIndexIfExists < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  # https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/250
  # That MR was added on gitlab-ee so we need to check if the index
  # already exists because we want to do is create an unique index instead.

  def up
    if index_exists?(:keys, :fingerprint)
      remove_index :keys, :fingerprint
    end
  end

  def down
    unless index_exists?(:keys, :fingerprint)
      add_concurrent_index :keys, :fingerprint
    end
  end
end
