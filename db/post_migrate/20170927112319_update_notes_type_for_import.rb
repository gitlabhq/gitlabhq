# rubocop:disable Migration/UpdateLargeTable
class UpdateNotesTypeForImport < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:notes, :type, 'Note') do |table, query|
      query.where(table[:type].eq('Github::Import::Note'))
    end
  end

  def down
  end
end
