# frozen_string_literal: true

class PrepareRepositoryLanguagesLanguageIdNotNullValidation < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  TABLE_NAME = :repository_languages
  CONSTRAINT_NAME = 'check_732edd0c38'

  def up
    # This constraint is GitLab.com-only and intentionally absent from structure.sql, which represents self-managed.
    return unless Gitlab.com_except_jh?

    prepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    return unless Gitlab.com_except_jh?

    unprepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end
end
