# frozen_string_literal: true

class ValidateIdentitiesUserIdForeignKey < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_5373344100'

  milestone '18.9'

  # TODO: FK to be validated synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/578135
  def up
    prepare_async_foreign_key_validation :identities, :user_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :identities, :user_id, name: FK_NAME
  end
end
