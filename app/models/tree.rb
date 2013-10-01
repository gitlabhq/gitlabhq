class Tree
  attr_accessor :entries, :readme

  def initialize(repository, sha, path = '/')
    path = '/' if path.blank?
    git_repo = repository.raw_repository
    @entries = Gitlab::Git::Tree.where(git_repo, sha, path)

    if readme_tree = @entries.find(&:readme?)
      @readme = Gitlab::Git::Blob.find(git_repo, sha, readme_tree.name)
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
end
