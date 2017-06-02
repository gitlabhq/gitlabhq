class BuildArtifactEntity < Grape::Entity
  include RequestAwareEntity

  expose :name do |build|
    build.name
  end

  expose :path do |build|
    download_namespace_project_job_artifacts_path(
      build.project.namespace,
      build.project,
      build)
  end
end
