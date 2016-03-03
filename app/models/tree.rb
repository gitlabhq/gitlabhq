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

    previewable_readmes = available_readmes.select do |blob|
      previewable?(blob.name)
    end

    plain_readmes = available_readmes.select do |blob|
      plain?(blob.name)
    end

    # Prioritize previewable over plain readmes
    readme_tree = previewable_readmes.first || plain_readmes.first

    # Return if we can't preview any of them
    if readme_tree.nil?
      return @readme = nil
    end

    readme_path = path == '/' ? readme_tree.name : File.join(path, readme_tree.name)

    git_repo = repository.raw_repository
    @readme = Gitlab::Git::Blob.find(git_repo, sha, readme_path)
    @readme.load_all_data!(git_repo)
    @readme
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
