# frozen_string_literal: true

class IndexTagSshSignaturesOnProjectAndObjectName < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  TABLE_NAME = :tag_ssh_signatures
  INDEX_NAME = 'index_tag_ssh_signatures_on_project_id_and_object_name'
  def up
    add_concurrent_index TABLE_NAME, [:project_id, :object_name], name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
