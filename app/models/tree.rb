class Tree
  attr_accessor :entries, :readme, :contribution_guide

  def initialize(repository, sha, path = '/')
    path = '/' if path.blank?
    git_repo = repository.raw_repository
    @entries = Gitlab::Git::Tree.where(git_repo, sha, path)

    if readme_tree = @entries.find(&:readme?)
      readme_path = path == '/' ? readme_tree.name : File.join(path, readme_tree.name)
      @readme = Gitlab::Git::Blob.find(git_repo, sha, readme_path)
    end

    if contribution_tree = @entries.find(&:contributing?)
      contribution_path = path == '/' ? contribution_tree.name : File.join(path, contribution_tree.name)
      @contribution_guide = Gitlab::Git::Blob.find(git_repo, sha, contribution_path)
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
