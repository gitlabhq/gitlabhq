# frozen_string_literal: true

class AddRunnersDescriptionIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_ci_runners_on_description_trigram'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, :description, name: INDEX_NAME, using: :gin, opclass: { description: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name :ci_runners, INDEX_NAME
  end
end
