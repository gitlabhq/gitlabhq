# frozen_string_literal: true

require Rails.root.join('db', 'post_migrate', '20210430134202_copy_adoption_snapshot_namespace.rb')

class RequireSnapshotNamespace < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    CopyAdoptionSnapshotNamespace.new.up

    add_not_null_constraint(:analytics_devops_adoption_snapshots, :namespace_id)
  end

  def down
    remove_not_null_constraint(:analytics_devops_adoption_snapshots, :namespace_id)
  end
end
