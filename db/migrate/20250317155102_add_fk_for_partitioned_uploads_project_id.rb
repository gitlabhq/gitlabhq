# frozen_string_literal: true

class AddFkForPartitionedUploadsProjectId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '17.11'

  def up
    # no-op due to a PRD incident
  end

  def down
    # no-op due to a PRD incident
  end
end
