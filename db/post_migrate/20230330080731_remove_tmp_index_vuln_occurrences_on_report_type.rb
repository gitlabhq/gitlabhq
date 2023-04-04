# frozen_string_literal: true

class RemoveTmpIndexVulnOccurrencesOnReportType < Gitlab::Database::Migration[2.1]
  def up
    # no-op
    # This migration was reverted as it removed a temporary index necessary for a background migration.
    # The migration file is re-added to ensure that all environments have the same list of migrations.
  end

  def down
    # no-op
  end
end
