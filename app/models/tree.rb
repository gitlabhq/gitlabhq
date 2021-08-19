# frozen_string_literal: true

class Tree
  include Gitlab::MarkupHelper
  include Gitlab::Utils::StrongMemoize

  attr_accessor :repository, :sha, :path, :entries, :cursor

  def initialize(repository, sha, path = '/', recursive: false, pagination_params: nil)
    path = '/' if path.blank?

    @repository = repository
    @sha = sha
    @path = path

    git_repo = @repository.raw_repository
    @entries, @cursor = Gitlab::Git::Tree.where(git_repo, @sha, @path, recursive, pagination_params)
  end

  def readme_path
    strong_memoize(:readme_path) do
      available_readmes = blobs.select do |blob|
        Gitlab::FileDetector.type_of(blob.name) == :readme
      end

      previewable_readmes = available_readmes.select do |blob|
        previewable?(blob.name)
      end

      plain_readmes = available_readmes.select do |blob|
        plain?(blob.name)
      end

      # Prioritize previewable over plain readmes
      entry = previewable_readmes.first || plain_readmes.first
      next nil unless entry

      if path == '/'
        entry.name
      else
        File.join(path, entry.name)
      end
    end
  end

  def readme
    strong_memoize(:readme) do
      repository.blob_at(sha, readme_path) if readme_path
    end
  end

  def trees
    @entries.select(&:dir?)
  end

  def blobs
    @entries.select(&:file?)
  end

  def submodules
    @entries.select(&:submodule?)
  end

  def sorted_entries
    trees + blobs + submodules
  end
end
