# frozen_string_literal: true

class Tree
  include Gitlab::Utils::StrongMemoize

  attr_accessor :repository, :sha, :path, :entries, :cursor, :ref_type

  def initialize(
    repository, sha, path = '/', recursive: false, skip_flat_paths: true, pagination_params: nil,
    ref_type: nil, rescue_not_found: true)
    path = '/' if path.blank?

    @repository = repository
    @sha = sha
    @path = path
    @ref_type = ExtractsRef::RefExtractor.ref_type(ref_type)
    git_repo = @repository.raw_repository

    ref = ExtractsRef::RefExtractor.qualify_ref(@sha, ref_type)

    @entries, @cursor = Gitlab::Git::Tree.tree_entries(
      repository: git_repo,
      sha: ref,
      path: @path,
      recursive: recursive,
      skip_flat_paths: skip_flat_paths,
      rescue_not_found: rescue_not_found,
      pagination_params: pagination_params
    )

    @entries.each do |entry|
      entry.ref_type = self.ref_type
    end
  end

  def readme_path
    strong_memoize(:readme_path) do
      available_readmes = blobs.select do |blob|
        Gitlab::FileDetector.type_of(blob.name) == :readme
      end

      previewable_readmes = available_readmes.select do |blob|
        Gitlab::MarkupHelper.previewable?(blob.name)
      end

      plain_readmes = available_readmes.select do |blob|
        Gitlab::MarkupHelper.plain?(blob.name)
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
