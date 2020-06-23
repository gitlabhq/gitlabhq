# frozen_string_literal: true

class SnippetStatistics < ApplicationRecord
  belongs_to :snippet

  validates :snippet, presence: true

  delegate :repository, to: :snippet

  def update_commit_count
    self.commit_count = repository.commit_count
  end

  def update_repository_size
    self.repository_size = repository.size.megabytes
  end

  def update_file_count
    count = if snippet.repository_exists?
              repository.ls_files(repository.root_ref).size
            else
              0
            end

    self.file_count = count
  end

  def refresh!
    update_commit_count
    update_repository_size
    update_file_count

    save!
  end
end
