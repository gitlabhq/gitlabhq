# frozen_string_literal: true

class AddTextLimitToGroupCiVariablesEnvironmentScope < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :ci_group_variables, :environment_scope, 255
  end

  def down
    remove_text_limit :ci_group_variables, :environment_scope
  end
end
