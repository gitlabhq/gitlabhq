# frozen_string_literal: true

class AddDigestAndReferenceToCdVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_column :cd_versions, :digest, :text, if_not_exists: true
    add_column :cd_versions, :reference, :text, if_not_exists: true

    add_text_limit :cd_versions, :digest, 255
    add_text_limit :cd_versions, :reference, 1024
  end

  def down
    remove_column :cd_versions, :reference, if_exists: true
    remove_column :cd_versions, :digest, if_exists: true
  end
end
