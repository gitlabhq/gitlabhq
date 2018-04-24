class ProjectStatistics < ActiveRecord::Base
  belongs_to :project
  belongs_to :namespace

  before_save :update_storage_size

  COLUMNS_TO_REFRESH = [:repository_size, :lfs_objects_size, :commit_count].freeze
  INCREMENTABLE_COLUMNS = [:build_artifacts_size].freeze

  def total_repository_size
    repository_size + lfs_objects_size
  end

  def refresh!(only: nil)
    COLUMNS_TO_REFRESH.each do |column, generator|
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

  def update_storage_size
    self.storage_size = repository_size + lfs_objects_size + build_artifacts_size
  end

  def self.increment_statistic(project_id, key, amount)
    raise ArgumentError, "Cannot increment attribute: #{key}" unless key.in?(INCREMENTABLE_COLUMNS)
    return if amount == 0

    where(project_id: project_id)
      .update_all(["#{key} = COALESCE(#{key}, 0) + (?)", amount])
  end
end
