# Adapter class to unify the interface between mounted uploaders and the
# Ci::Artifact model
# Meant to be prepended so the interface can stay the same
module ArtifactMigratable
  def artifacts_file
    job_artifacts_archive&.file || legacy_artifacts_file
  end

  def artifacts_metadata
    job_artifacts_metadata&.file || legacy_artifacts_metadata
  end

  def artifacts?
    !artifacts_expired? && artifacts_file.exists?
  end

  def artifacts_metadata?
    artifacts? && artifacts_metadata.exists?
  end

  def artifacts_file_changed?
    job_artifacts_archive&.file_changed? || attribute_changed?(:artifacts_file)
  end

  def remove_artifacts_file!
    if job_artifacts_archive
      job_artifacts_archive.destroy
    else
      remove_legacy_artifacts_file!
    end
  end

  def remove_artifacts_metadata!
    if job_artifacts_metadata
      job_artifacts_metadata.destroy
    else
      remove_legacy_artifacts_metadata!
    end
  end

  def artifacts_size
    read_attribute(:artifacts_size).to_i + job_artifacts.sum(:size).to_i
  end
end
