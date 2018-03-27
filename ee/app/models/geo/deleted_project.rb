class Geo::DeletedProject
  attr_reader :id, :name, :disk_path

  def initialize(id:, name:, disk_path:, repository_storage:)
    @id = id
    @name = name
    @disk_path = disk_path
    @repository_storage = repository_storage
  end

  alias_method :full_path, :disk_path

  def repository
    @repository ||= Repository.new(disk_path, self)
  end

  def repository_storage
    @repository_storage ||= Gitlab::CurrentSettings.pick_repository_storage
  end

  def repository_storage_path
    Gitlab.config.repositories.storages[repository_storage]&.legacy_disk_path
  end

  def wiki
    @wiki ||= ProjectWiki.new(self, nil)
  end

  def wiki_path
    wiki.disk_path
  end

  # When we remove project we move the repository to path+deleted.git then
  # outside the transaction we schedule removal of path+deleted with Sidekiq
  # through the run_after_commit callback. In a Geo secondary node, we don't
  # attempt to remove the repositories inside a transaction because we don't
  # have access to the original model anymore, we just need to perform some
  # cleanup. This method will run the given block to remove repositories
  # immediately otherwise will leave us with stalled repositories on disk.
  def run_after_commit(&block)
    instance_eval(&block)
  end
end
