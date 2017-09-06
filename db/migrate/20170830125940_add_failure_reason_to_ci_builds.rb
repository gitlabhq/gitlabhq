class AddFailureReasonToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_builds, :failure_reason, :integer
  end
end
