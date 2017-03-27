class AddHeadPipelineForEachMergeRequest < ActiveRecord::Migration
  DOWNTIME = false

  class Pipeline < ActiveRecord::Base
    self.table_name = "ci_pipelines"

    def self.last_per_branch
      select('ref, MAX(id) as head_id, project_id').group(:ref).group(:project_id)
    end
  end

  class MergeRequest < ActiveRecord::Base; end

  def up
    Pipeline.last_per_branch.each do |pipeline|
      mrs = MergeRequest.where(source_branch: pipeline.ref, source_project_id: pipeline.project_id)
      mrs.update_all(head_pipeline_id: pipeline.head_id)
    end
  end

  def down
  end
end
