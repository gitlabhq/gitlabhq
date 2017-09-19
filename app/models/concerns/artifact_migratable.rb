# Adapter class to unify the interface between mounted uploaders and the
# Ci::Artifact model
# Meant to be prepended so the interface can stay the same
module ArtifactMigratable
  def artifacts_file
    artifacts.archive.first&.file || super
  end

  def artifacts_metadata
    artifacts.metadata.first&.file || super
  end

  def artifacts?
    byebug
    !artifacts_expired? && artifacts_file.exists?
  end

  def artifacts_metadata?
    artifacts? && artifacts_metadata.exists?
  end

  def remove_artifacts_file!
    artifacts_file.remove!
  end

  def remove_artifacts_metadata!
    artifacts_metadata.remove!
  end

  def artifacts_file=(file)
    artifacts.create(project: project, type: :archive, file: file)
  end

  def artifacts_metadata=(file)
    artifacts.create(project: project, type: :metadata, file: file)
  end
end
