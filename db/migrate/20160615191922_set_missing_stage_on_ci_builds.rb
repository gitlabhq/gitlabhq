# rubocop:disable Migration/UpdateLargeTable
# rubocop:disable Migration/UpdateColumnInBatches
class SetMissingStageOnCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    update_column_in_batches(:ci_builds, :stage, :test) do |table, query|
      query.where(table[:stage].eq(nil))
    end
  end
end
