# frozen_string_literal: true

class ProjectStatistics < ApplicationRecord
  include CounterAttribute

  belongs_to :project
  belongs_to :namespace

  attribute :wiki_size, default: 0
  attribute :snippets_size, default: 0

  ignore_column :vulnerability_count, remove_with: '17.7', remove_after: '2024-11-15'

  counter_attribute :build_artifacts_size
  counter_attribute :packages_size

  counter_attribute_after_commit do |project_statistics|
    project_statistics.refresh_storage_size!

    Namespaces::ScheduleAggregationWorker.perform_async(project_statistics.namespace_id)
  end

  after_commit :refresh_storage_size!, on: :update, if: -> { storage_size_components_changed? }

  COLUMNS_TO_REFRESH = [:repository_size, :wiki_size, :lfs_objects_size, :commit_count, :snippets_size, :uploads_size, :container_registry_size].freeze
  INCREMENTABLE_COLUMNS = [
    :pipeline_artifacts_size,
    :snippets_size
  ].freeze
  NAMESPACE_RELATABLE_COLUMNS = [:repository_size, :wiki_size, :lfs_objects_size, :uploads_size, :container_registry_size].freeze
  STORAGE_SIZE_COMPONENTS = [
    :repository_size,
    :wiki_size,
    :lfs_objects_size,
    :build_artifacts_size,
    :packages_size,
    :snippets_size,
    :uploads_size
  ].freeze

  scope :for_project_ids, ->(project_ids) { where(project_id: project_ids) }

  scope :for_namespaces, ->(namespaces) { where(namespace: namespaces) }

  def total_repository_size
    repository_size + lfs_objects_size
  end

  def refresh!(only: [])
    return if Gitlab::Database.read_only?

    columns_to_update = only.empty? ? COLUMNS_TO_REFRESH : COLUMNS_TO_REFRESH & only
    columns_to_update.each do |column|
      public_send("update_#{column}") # rubocop:disable GitlabSecurity/PublicSend
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
    self.repository_size = project.repository.recent_objects_size.megabytes
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
  # Therefore, any call to any of those methods will return nil instead of 0.
  #
  # These two methods provide consistency and avoid returning nil.
  def wiki_size
    super.to_i
  end

  def snippets_size
    super.to_i
  end

  # Since this incremental update method does not update the storage_size directly,
  # we have to update the storage_size separately in an after_commit action.
  def refresh_storage_size!
    self.class.where(id: id).update_all("storage_size = #{storage_size_sum}")
  end

  # For counter attributes, storage_size will be refreshed after the counter is flushed,
  # through counter_attribute_after_commit
  #
  # For non-counter attributes, storage_size is updated depending on key => [columns] in INCREMENTABLE_COLUMNS
  def self.increment_statistic(project, key, increment)
    return if project.pending_delete?

    project.statistics.try do |project_statistics|
      project_statistics.increment_statistic(key, increment)
    end
  end

  def self.bulk_increment_statistic(project, key, increments)
    return if project.pending_delete?

    project.statistics.try do |project_statistics|
      project_statistics.bulk_increment_statistic(key, increments)
    end
  end

  def increment_statistic(key, increment)
    raise ArgumentError, "Cannot increment attribute: #{key}" unless incrementable_attribute?(key)

    increment_counter(key, increment)
  end

  def bulk_increment_statistic(key, increments)
    raise ArgumentError, "Cannot increment attribute: #{key}" unless incrementable_attribute?(key)

    bulk_increment_counter(key, increments)
  end

  # Build artifacts & packages are not included in the project export
  def export_size
    storage_size - build_artifacts_size - packages_size
  end

  private

  def incrementable_attribute?(key)
    INCREMENTABLE_COLUMNS.include?(key) || counter_attribute_enabled?(key)
  end

  def storage_size_components
    STORAGE_SIZE_COMPONENTS
  end

  def storage_size_sum
    storage_size_components.map { |component| "COALESCE (#{component}, 0)" }.join(' + ').freeze
  end

  def schedule_namespace_aggregation_worker
    run_after_commit do
      Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
    end
  end

  def storage_size_components_changed?
    (previous_changes.keys & STORAGE_SIZE_COMPONENTS.map(&:to_s)).any?
  end
end

ProjectStatistics.prepend_mod_with('ProjectStatistics')
