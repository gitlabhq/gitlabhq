# frozen_string_literal: true

class ProjectStatistics < ApplicationRecord
  include AfterCommitQueue

  belongs_to :project
  belongs_to :namespace

  default_value_for :wiki_size, 0
  default_value_for :snippets_size, 0

  before_save :update_storage_size

  COLUMNS_TO_REFRESH = [:repository_size, :wiki_size, :lfs_objects_size, :commit_count, :snippets_size].freeze
  INCREMENTABLE_COLUMNS = { build_artifacts_size: %i[storage_size], packages_size: %i[storage_size], snippets_size: %i[storage_size] }.freeze
  NAMESPACE_RELATABLE_COLUMNS = [:repository_size, :wiki_size, :lfs_objects_size].freeze

  scope :for_project_ids, ->(project_ids) { where(project_id: project_ids) }

  scope :for_namespaces, -> (namespaces) { where(namespace: namespaces) }
  scope :with_any_ci_minutes_used, -> { where.not(shared_runners_seconds: 0) }

  def total_repository_size
    repository_size + lfs_objects_size
  end

  def refresh!(only: [])
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
    self.lfs_objects_size = project.lfs_objects.sum(:size)
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
    storage_size = repository_size + wiki_size + lfs_objects_size + build_artifacts_size + packages_size
    # The `snippets_size` column was added on 20200622095419 but db/post_migrate/20190527194900_schedule_calculate_wiki_sizes.rb
    # might try to update project statistics before the `snippets_size` column has been created.
    storage_size += snippets_size if self.class.column_names.include?('snippets_size')

    self.storage_size = storage_size
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

  private

  def schedule_namespace_aggregation_worker
    run_after_commit do
      Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
    end
  end
end

ProjectStatistics.prepend_if_ee('EE::ProjectStatistics')
