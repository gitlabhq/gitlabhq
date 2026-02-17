# frozen_string_literal: true

class ValidateForeignKeyOnGpgKeySubkeysUserId < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  FK_NAME = :fk_c0b9a5787c

  # TODO: FK to be validated synchronously in https://gitlab.com/gitlab-org/gitlab/-/work_items/582331
  def up
    prepare_async_foreign_key_validation :gpg_key_subkeys, :user_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :gpg_key_subkeys, :user_id, name: FK_NAME
  end
end
