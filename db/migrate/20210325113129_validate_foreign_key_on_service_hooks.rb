# frozen_string_literal: true

class ValidateForeignKeyOnServiceHooks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  CONSTRAINT_NAME = 'fk_d47999a98a'

  def up
    validate_foreign_key :web_hooks, :service_id, name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
