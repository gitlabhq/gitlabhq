# frozen_string_literal: true

class PrepareProgrammingLanguagesLanguageIdNotNullValidation < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  TABLE_NAME = :programming_languages
  CONSTRAINT_NAME = 'check_4e6f0ff707'

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
