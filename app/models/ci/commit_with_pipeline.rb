# frozen_string_literal: true

class Ci::CommitWithPipeline < SimpleDelegator
  include Presentable

  def initialize(commit)
    @latest_pipelines = {}
    super(commit)
  end

  def pipelines
    project.ci_pipelines.where(sha: sha)
  end

  def last_pipeline
    strong_memoize(:last_pipeline) do
      pipelines.last
    end
  end

  def lazy_latest_pipeline
    BatchLoader.for(sha).batch do |shas, loader|
      preload_pipelines = project.ci_pipelines.latest_pipeline_per_commit(shas.compact)

      shas.each do |sha|
        pipeline = preload_pipelines[sha]

        loader.call(sha, pipeline)
      end
    end
  end

  def latest_pipeline(ref = nil)
    @latest_pipelines.fetch(ref) do |ref|
      @latest_pipelines[ref] = if ref
                                 latest_pipeline_for_project(ref, project)
                               else
                                 lazy_latest_pipeline&.itself
                               end
    end
  end

  def latest_pipeline_for_project(ref, pipeline_project)
    pipeline_project.ci_pipelines.latest_pipeline_per_commit(id, ref)[id]
  end

  def set_latest_pipeline_for_ref(ref, pipeline)
    @latest_pipelines[ref] = pipeline
  end

  def status(ref = nil)
    latest_pipeline(ref)&.status
  end
end
