class Tree
  include Gitlab::MarkupHelper

  attr_accessor :repository, :sha, :path, :entries

  def initialize(repository, sha, path = '/')
    path = '/' if path.blank?

    @repository = repository
    @sha = sha
    @path = path

    git_repo = @repository.raw_repository
    @entries = Gitlab::Git::Tree.where(git_repo, @sha, @path)
  end

  def readme
    return @readme if defined?(@readme)

    available_readmes = blobs.select(&:readme?)

    if available_readmes.count == 0
      return @readme = nil
    end

    # Take the first previewable readme, or the first available readme, if we
    # can't preview any of them
    readme_tree = available_readmes.find do |readme|
      previewable?(readme.name)
    end || available_readmes.first

    readme_path = path == '/' ? readme_tree.name : File.join(path, readme_tree.name)

    git_repo = repository.raw_repository
    @readme = Gitlab::Git::Blob.find(git_repo, sha, readme_path)
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
