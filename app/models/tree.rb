class Tree
  include Gitlab::MarkdownHelper

  attr_accessor :entries, :readme, :contribution_guide

  def initialize(repository, sha, path = '/', recursive)
    path = '/' if path.blank?
    git_repo = repository.raw_repository

    if recursive == '1'
      @entries = get_recursive_entries(git_repo, sha, path)
    else
      @entries = Gitlab::Git::Tree.where(git_repo, sha, path)
    end

    available_readmes = @entries.select(&:readme?)

    if available_readmes.count > 0
      # If there is more than 1 readme in tree, find readme which is supported
      # by markup renderer.
      if available_readmes.length > 1
        supported_readmes = available_readmes.select do |readme|
          previewable?(readme.name)
        end

        # Take the first supported readme, or the first available readme, if we
        # don't support any of them
        readme_tree = supported_readmes.first || available_readmes.first
      else
        readme_tree = available_readmes.first
      end

      readme_path = path == '/' ? readme_tree.name : File.join(path, readme_tree.name)
      @readme = Gitlab::Git::Blob.find(git_repo, sha, readme_path)
    end

    if contribution_tree = @entries.find(&:contributing?)
      contribution_path = path == '/' ? contribution_tree.name : File.join(path, contribution_tree.name)
      @contribution_guide = Gitlab::Git::Blob.find(git_repo, sha, contribution_path)
    end
  end

  def get_recursive_entries(git_repo, sha, path)
    entries =  Gitlab::Git::Tree.where(git_repo, sha, path)

    entries.select(&:dir?).each do |t|
      entries += get_recursive_entries(git_repo, sha,t.path)
    end
    entries
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
