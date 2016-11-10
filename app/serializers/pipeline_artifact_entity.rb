class PipelineArtifactEntity < Grape::Entity
  include RequestAwareEntity

  expose :name do |build|
    build.name
  end

  expose :url do |build|
    download_namespace_project_build_artifacts_path(
      pipeline.project.namespace,
      pipeline.project,
      build)
  end
end
