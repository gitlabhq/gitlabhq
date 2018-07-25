# frozen_string_literal: true

class ProjectStatistics < ActiveRecord::Base
  belongs_to :project
  belongs_to :namespace

  before_save :update_storage_size

  COLUMNS_TO_REFRESH = [:repository_size, :lfs_objects_size, :commit_count].freeze
  INCREMENTABLE_COLUMNS = { build_artifacts_size: %i[storage_size] }.freeze

  def shared_runners_minutes
    shared_runners_seconds.to_i / 60
  end

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

  # Since this incremental update method does not call update_storage_size above,
  # we have to update the storage_size here as additional column.
  # Additional columns are updated depending on key => [columns], which allows
  # to update statistics which are and also those which aren't included in storage_size
  # or any other additional summary column in the future.
  def self.increment_statistic(project_id, key, amount)
    raise ArgumentError, "Cannot increment attribute: #{key}" unless INCREMENTABLE_COLUMNS.key?(key)
    return if amount == 0

    where(project_id: project_id)
      .columns_to_increment(key, amount)
  end

  def self.columns_to_increment(key, amount)
    updates = ["#{key} = COALESCE(#{key}, 0) + (#{amount})"]

    if (additional = INCREMENTABLE_COLUMNS[key])
      additional.each do |column|
        updates << "#{column} = COALESCE(#{column}, 0) + (#{amount})"
      end
    end

    update_all(updates.join(', '))
  end
end
