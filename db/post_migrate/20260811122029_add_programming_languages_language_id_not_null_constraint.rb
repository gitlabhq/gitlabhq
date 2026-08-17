# frozen_string_literal: true

class AddProgrammingLanguagesLanguageIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  disable_ddl_transaction!

  def up
    # This constraint is GitLab.com-only and intentionally absent from structure.sql, which represents self-managed.
    return unless Gitlab.com_except_jh?

    add_not_null_constraint :programming_languages, :language_id, validate: false
  end

  def down
    return unless Gitlab.com_except_jh?

    remove_not_null_constraint :programming_languages, :language_id
  end
end
