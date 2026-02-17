# frozen_string_literal: true

class SyncValidateForeignKeyOnGpgKeySubkeysUserId < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  FK_NAME = :fk_c0b9a5787c

  def up
    # NOTE: FK was validated asynchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218818
    validate_foreign_key :gpg_key_subkeys, :user_id, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data
  end
end
