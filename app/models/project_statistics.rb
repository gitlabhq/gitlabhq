# frozen_string_literal: true

class ProjectStatistics < ApplicationRecord
  include AfterCommitQueue
  include CounterAttribute

  belongs_to :project
  belongs_to :namespace

  default_value_for :wiki_size, 0
  default_value_for :snippets_size, 0

  counter_attribute :build_artifacts_size

  counter_attribute_after_flush do |project_statistic|
    project_statistic.refresh_storage_size!

    Namespaces::ScheduleAggregationWorker.perform_async(project_statistic.namespace_id)
  end

  before_save :update_storage_size

  COLUMNS_TO_REFRESH = [:repository_size, :wiki_size, :lfs_objects_size, :commit_count, :snippets_size, :uploads_size, :container_registry_size].freeze
  INCREMENTABLE_COLUMNS = {
    packages_size: %i[storage_size],
    pipeline_artifacts_size: %i[storage_size],
    snippets_size: %i[storage_size]
  }.freeze
  NAMESPACE_RELATABLE_COLUMNS = [:repository_size, :wiki_size, :lfs_objects_size, :uploads_size, :container_registry_size].freeze

  scope :for_project_ids, ->(project_ids) { where(project_id: project_ids) }

  scope :for_namespaces, -> (namespaces) { where(namespace: namespaces) }

  def total_repository_size
    repository_size + lfs_objects_size
  end

  def refresh!(only: [])
    return if Gitlab::Database.read_only?

    COLUMNS_TO_REFRESH.each do |column, generator|
      if only.empty? || only.include?(column)
        public_send("update_#{column}") # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    if only.empty? || only.any? { |column| NAMESPACE_RELATABLE_COLUMNS.include?(column) }
      schedule_namespace_aggregation_worker
    end

    save!
  end

  def update_commit_count
    self.commit_count = project.repository.commit_count
  end

  def update_repository_size
    self.repository_size = project.repository.size * 1.megabyte
  end

  def update_wiki_size
    self.wiki_size = project.wiki.repository.size * 1.megabyte
  end

  def update_snippets_size
    self.snippets_size = project.snippets.with_statistics.sum(:repository_size)
  end

  def update_lfs_objects_size
    self.lfs_objects_size = LfsObject.joins(:lfs_objects_projects).where(lfs_objects_projects: { project_id: project.id }).sum(:size)
  end

  def update_uploads_size
    self.uploads_size = project.uploads.sum(:size)
  end

  def update_container_registry_size
    self.container_registry_size = project.container_repositories_size || 0
  end

  # `wiki_size` and `snippets_size` have no default value in the database
  # and the column can be nil.
  # This means that, when the columns were added, all rows had nil
  # values on them.
  # Therefore, any call to any of those methods will return nil instead
  # of 0, because `default_value_for` works with new records, not existing ones.
  #
  # These two methods provide consistency and avoid returning nil.
  def wiki_size
    super.to_i
  end

  def snippets_size
    super.to_i
  end

  def update_storage_size
    storage_size = repository_size +
                   wiki_size +
                   lfs_objects_size +
                   build_artifacts_size +
                   packages_size +
                   snippets_size +
                   pipeline_artifacts_size +
                   uploads_size

    self.storage_size = storage_size
  end

  def refresh_storage_size!
    update_storage_size
    save!
  end

  # Since this incremental update method does not call update_storage_size above through before_save,
  # we have to update the storage_size separately.
  #
  # For counter attributes, storage_size will be refreshed after the counter is flushed,
  # through counter_attribute_after_flush
  #
  # For non-counter attributes, storage_size is updated depending on key => [columns] in INCREMENTABLE_COLUMNS
  def self.increment_statistic(project, key, amount)
    raise ArgumentError, "Cannot increment attribute: #{key}" unless incrementable_attribute?(key)
    return if amount == 0

    project.statistics.try do |project_statistics|
      if counter_attribute_enabled?(key)
        project_statistics.delayed_increment_counter(key, amount)
      else
        legacy_increment_statistic(project, key, amount)
      end
    end
  end

  def self.legacy_increment_statistic(project, key, amount)
    where(project_id: project.id).columns_to_increment(key, amount)

    Namespaces::ScheduleAggregationWorker.perform_async( # rubocop: disable CodeReuse/Worker
      project.namespace_id)
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

  def self.incrementable_attribute?(key)
    INCREMENTABLE_COLUMNS.key?(key) || counter_attribute_enabled?(key)
  end

  private

  def schedule_namespace_aggregation_worker
    run_after_commit do
      Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
    end
  end
end

ProjectStatistics.prepend_mod_with('ProjectStatistics')
