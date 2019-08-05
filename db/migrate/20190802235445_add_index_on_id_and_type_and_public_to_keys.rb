# frozen_string_literal: true

class AddIndexOnIdAndTypeAndPublicToKeys < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = "index_on_deploy_keys_id_and_type_and_public"

  def up
    add_concurrent_index(:keys,
                         [:id, :type],
                         where: "public = 't'",
                         unique: true,
                         name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:keys, INDEX_NAME)
  end
end
