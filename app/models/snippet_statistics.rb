# frozen_string_literal: true

class SnippetStatistics < ApplicationRecord
  include AfterCommitQueue
  include UpdateProjectStatistics

  belongs_to :snippet

  validates :snippet, presence: true

  update_project_statistics project_statistics_name: :snippets_size, statistic_attribute: :repository_size

  delegate :repository, :project, :project_id, to: :snippet

  after_save :update_author_root_storage_statistics, if: :update_author_root_storage_statistics?
  after_destroy :update_author_root_storage_statistics, unless: :project_snippet?

  def update_commit_count
    self.commit_count = repository.commit_count
  end

  def update_repository_size
    self.repository_size = repository.size.megabytes
  end

  def update_file_count
    count = if snippet.repository_exists?
              repository.ls_files(snippet.default_branch).size
            else
              0
            end

    self.file_count = count
  end

  def refresh!
    return if Gitlab::Database.main.read_only?

    update_commit_count
    update_repository_size
    update_file_count

    save!
  end

  private

  alias_method :original_update_project_statistics_after_save?, :update_project_statistics_after_save?
  def update_project_statistics_after_save?
    project_snippet? && original_update_project_statistics_after_save?
  end

  alias_method :original_update_project_statistics_after_destroy?, :update_project_statistics_after_destroy?
  def update_project_statistics_after_destroy?
    project_snippet? && original_update_project_statistics_after_destroy?
  end

  def update_author_root_storage_statistics?
    !project_snippet? && saved_change_to_repository_size?
  end

  def update_author_root_storage_statistics
    run_after_commit do
      Namespaces::ScheduleAggregationWorker.perform_async(snippet.author.namespace_id)
    end
  end

  def project_snippet?
    snippet.is_a?(ProjectSnippet)
  end
end
