# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveTemplateFromLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration removes an existing column'

  disable_ddl_transaction!

  def up
    update_column_in_batches(:labels, :label_type, 0) do |table, query|
      query.where(table[:template].eq(true))
    end

    remove_column :labels, :template
  end

  def down
    add_column_with_default :labels, :template, :boolean, default: false

    update_column_in_batches(:labels, :template, true) do |table, query|
      query.where(table[:label_type].eq(0))
    end
  end
end
