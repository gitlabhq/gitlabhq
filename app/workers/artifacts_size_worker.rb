class ArtifactsSizeWorker
  include Sidekiq::Worker

  def perform(id)
    build = Ci::Build.find(id)

    build.artifacts_size = if build.artifacts_file.exists?
                             build.artifacts_file.size
                           else
                             nil
                           end

    build.save
  end
end
