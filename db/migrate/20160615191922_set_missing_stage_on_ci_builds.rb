class SetMissingStageOnCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def up
    update_column_in_batches(:ci_builds, :stage, :test) do |table, query|
      query.where(table[:stage].eq(nil))
    end
  end
end
