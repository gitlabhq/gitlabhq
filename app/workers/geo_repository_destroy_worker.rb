class GeoRepositoryDestroyWorker
  include Sidekiq::Worker
  include GeoQueue
  include Gitlab::ShellAdapter

  def perform(id, name, full_path)
    repository_storage = probe_repository_storage(full_path)

    # We don't have access to the original model anymore, so we are
    # rebuilding only what our service class requires
    project = ::Geo::DeletedProject.new(id: id, name: name, full_path: full_path, repository_storage: repository_storage)

    ::Projects::DestroyService.new(project, nil).geo_replicate
  end

  private

  # Detect in which repository_storage the project repository is stored.
  #
  # As we don't have access to `repository_storage` from the data in the Hook notification
  # we need to probe on all existing ones.
  #
  # if we don't find it means it has already been deleted and we just return
  def probe_repository_storage(full_path)
    Gitlab.config.repositories.storages.each do |repository_storage, rs_data|
      return repository_storage if gitlab_shell.exists?(rs_data['path'], full_path + '.git')
    end

    nil
  end
end
