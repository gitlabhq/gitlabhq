# frozen_string_literal: true

class CreateNugetDependencyLinkMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'packages_nuget_dependency_link_metadata_target_framework_constraint'

  def up
    unless table_exists?(:packages_nuget_dependency_link_metadata)
      create_table :packages_nuget_dependency_link_metadata, id: false do |t|
        t.references :dependency_link, primary_key: true, default: nil, foreign_key: { to_table: :packages_dependency_links, on_delete: :cascade }, index: { name: 'index_packages_nuget_dl_metadata_on_dependency_link_id' }, type: :bigint
        t.text :target_framework, null: false
      end
    end

    add_text_limit :packages_nuget_dependency_link_metadata, :target_framework, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    drop_table :packages_nuget_dependency_link_metadata
  end
end
