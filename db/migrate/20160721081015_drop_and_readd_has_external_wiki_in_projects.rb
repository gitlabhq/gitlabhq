# rubocop:disable Migration/UpdateLargeTable
# rubocop:disable Migration/UpdateColumnInBatches
class DropAndReaddHasExternalWikiInProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:projects, :has_external_wiki, nil) do |table, query|
      query.where(table[:has_external_wiki].not_eq(nil))
    end
  end

  def down
  end
end
