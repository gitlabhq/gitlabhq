class CacheRawArtifactWorker
  include ApplicationWorker
  include PipelineBackgroundQueue

  def perform(job_artifact_id)
    state_flag do
      Ci::JobArtifact.find_by(id: job_artifact_id).compressed.try do |job_artifact|
        job_artifact.file.use_file do |artifact_path|
          local_cache_path = "path/to/cache" # TODO: 
          extract_zip_archive!(from: artifact_path, to: local_cache_path)
          job_artifact.cache!(local_cache_path)
        end
      end
    end
  end

  def state_flag(&block)
    Gitlab::Redis::Cache.with do |redis|
      return if redis.exist(job_artifact.raw_name)

      redis.set(job_artifact.raw_name, ttl: 1.week)
    end

    yield
  ensure
    Gitlab::Redis::Cache.with do |redis|
      redis.del(job_artifact.raw_name)
    end
  end
end
