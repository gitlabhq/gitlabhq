module Migration
  ##
  # This is an example of a per-resource migration.
  #
  # We can put these into db/background_migrations etc.
  #
  class PipelineExample < Gitlab::Database::BackgroundMigration
    class MyPipeline < ActiveRecord::Base
      self.table_name = 'ci_pipelines'
    end

    def perform!
      MyPipeline.find(@id).update_columns(status: 'success', duration: 1234)
    end
  end
end
