# frozen_string_literal: true

class AddPartialIndexForCiBuildsToken < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  NAME = 'index_ci_builds_on_token_partial'

  def up
    add_concurrent_index :ci_builds, :token, unique: true, where: 'token IS NOT NULL', name: NAME
  end

  def down
    remove_concurrent_index_by_name :ci_builds, NAME
  end
end
