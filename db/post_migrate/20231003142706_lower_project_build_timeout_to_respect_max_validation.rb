# frozen_string_literal: true

class LowerProjectBuildTimeoutToRespectMaxValidation < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Project < MigrationRecord
    self.table_name = 'projects'

    include EachBatch
  end

  def up
    Project.where("build_timeout >= #{1.month.to_i}").each_batch(of: 10) do |records|
      records.update_all(build_timeout: (1.month - 1.second).to_i)
    end
  end

  def down
    # no-op
  end
end
