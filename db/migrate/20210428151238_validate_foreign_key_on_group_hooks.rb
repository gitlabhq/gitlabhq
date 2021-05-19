# frozen_string_literal: true

class ValidateForeignKeyOnGroupHooks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  CONSTRAINT_NAME = 'fk_rails_d35697648e'

  def up
    validate_foreign_key :web_hooks, :group_id, name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
