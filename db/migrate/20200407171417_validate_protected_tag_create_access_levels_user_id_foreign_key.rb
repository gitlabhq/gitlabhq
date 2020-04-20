# frozen_string_literal: true

class ValidateProtectedTagCreateAccessLevelsUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_protected_tag_create_access_levels_user_id'

  def up
    validate_foreign_key :protected_tag_create_access_levels, :user_id, name: CONSTRAINT_NAME
  end

  def down
    # no op
  end
end
