# rubocop:disable Migration/UpdateLargeTable
class UpdateLegacyDiffNotesTypeForImport < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:notes, :type, 'LegacyDiffNote') do |table, query|
      query.where(table[:type].eq('Github::Import::LegacyDiffNote'))
    end
  end

  def down
  end
end
