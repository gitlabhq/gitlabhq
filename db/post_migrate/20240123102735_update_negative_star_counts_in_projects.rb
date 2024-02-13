# frozen_string_literal: true

class UpdateNegativeStarCountsInProjects < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Project < MigrationRecord
    self.table_name = :projects

    include EachBatch
  end

  def up
    Project.where('star_count < 0').each_batch(of: 100) do |records|
      records.update_all(star_count: 0)
    end
  end

  def down
    # no-op
  end
end
