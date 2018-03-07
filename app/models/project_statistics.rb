class ProjectStatistics < ActiveRecord::Base
  belongs_to :project
  belongs_to :namespace

  before_save :update_storage_size

  STORAGE_COLUMNS = [:repository_size, :lfs_objects_size, :build_artifacts_size].freeze
  STATISTICS_COLUMNS = [:commit_count] + STORAGE_COLUMNS

  def total_repository_size
    repository_size + lfs_objects_size
  end

  def refresh!(only: nil)
    STATISTICS_COLUMNS.each do |column, generator|
      if only.blank? || only.include?(column)
        public_send("update_#{column}") # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    save!
  end

  def update_commit_count
    self.commit_count = project.repository.commit_count
  end

  # Repository#size needs to be converted from MB to Byte.
  def update_repository_size
    self.repository_size = project.repository.size * 1.megabyte
  end

  def update_lfs_objects_size
    self.lfs_objects_size = project.lfs_objects.sum(:size)
  end

  def update_build_artifacts_size
    self.build_artifacts_size =
      project.builds.sum(:artifacts_size) +
      Ci::JobArtifact.artifacts_size_for(self.project)
  end

  def update_storage_size
    self.storage_size = STORAGE_COLUMNS.sum(&method(:read_attribute))
  end
end
