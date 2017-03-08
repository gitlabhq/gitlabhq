# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateMirrorWhenEmptyImportUrlInProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    update_column_in_batches(:projects, :mirror, false) do |table, query|
      query.where(table[:import_url].eq(nil).or(table[:import_url].eq('')))
    end
  end
end
