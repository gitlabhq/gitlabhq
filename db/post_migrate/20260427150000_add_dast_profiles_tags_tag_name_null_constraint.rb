# frozen_string_literal: true

class AddDastProfilesTagsTagNameNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  TABLE_NAME = :dast_profiles_tags
  COLUMN_NAME = :tag_name
  CONSTRAINT_NAME = 'check_tag_name_not_null'

  def up
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME)
  end
end
