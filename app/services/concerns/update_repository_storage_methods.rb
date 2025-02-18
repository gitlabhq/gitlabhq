# frozen_string_literal: true

module UpdateRepositoryStorageMethods
  include Gitlab::Utils::StrongMemoize

  MAX_ERROR_LENGTH = 256

  Error = Class.new(StandardError)

  attr_reader :repository_storage_move

  delegate :container, :source_storage_name, :destination_storage_name, to: :repository_storage_move

  def initialize(repository_storage_move)
    @repository_storage_move = repository_storage_move
  end

  def execute
    response = repository_storage_move.with_lock do
      next ServiceResponse.success unless repository_storage_move.scheduled?

      repository_storage_move.start!

      nil
    end

    return response if response

    unless same_filesystem?
      # Mirror the object pool first, as we'll later provide the pool's disk path as
      # partitioning hints when mirroring member repositories.
      mirror_object_pool(destination_storage_name)
      mirror_repositories
    end

    repository_storage_move.transaction do
      track_repository(destination_storage_name)
    end

    repository_storage_move.finish_replication!

    remove_old_paths unless same_filesystem?

    repository_storage_move.finish_cleanup!

    ServiceResponse.success
  rescue StandardError => e
    repository_storage_move.update_column(:error_message, e.message.truncate(MAX_ERROR_LENGTH))
    repository_storage_move.do_fail!

    Gitlab::ErrorTracking.track_and_raise_exception(e, container_klass: container.class.to_s, container_path: container.full_path)
  end

  private

  def track_repository(destination_shard)
    raise NotImplementedError
  end

  def mirror_repositories
    raise NotImplementedError
  end

  def mirror_object_pool(_destination_shard)
    # no-op, redefined for Projects::UpdateRepositoryStorageService
    nil
  end

  def mirror_repository(type:)
    unless wait_for_pushes(type)
      raise Error, s_('UpdateRepositoryStorage|Timeout waiting for %{type} repository pushes') % { type: type.name }
    end

    # `Projects::UpdateRepositoryStorageService`` expects the repository it is
    # moving to have a `Project` as a container.
    # This hack allows design repos to also be moved as part of a project move
    # as before.
    # The alternative to this hack is to setup a service like
    # `Snippets::UpdateRepositoryStorageService' and a corresponding worker like
    # `Snippets::UpdateRepositoryStorageWorker` for snippets.
    #
    # Gitlab issue: https://gitlab.com/gitlab-org/gitlab/-/issues/423429

    repository = type.repository_for(type.design? ? container.design_management_repository : container)
    full_path = repository.full_path
    raw_repository = repository.raw

    # Initialize a git repository on the target path
    new_repository = Gitlab::Git::Repository.new(
      destination_storage_name,
      raw_repository.relative_path,
      raw_repository.gl_repository,
      full_path
    )

    # Provide the object pool's disk path as a partitioning hint to Gitaly. This
    # ensures Gitaly creates the repository in the same partition as its pool, so
    # they can be correctly linked.
    object_pool = repository.project&.pool_repository&.object_pool
    hint = object_pool ? object_pool.relative_path : ""

    ::Repositories::ReplicateService.new(raw_repository)
      .execute(new_repository, type.name, partition_hint: hint)
  end

  def same_filesystem?
    strong_memoize(:same_filesystem) do
      Gitlab::GitalyClient.filesystem_id(source_storage_name) == Gitlab::GitalyClient.filesystem_id(destination_storage_name)
    end
  end

  def remove_old_paths
    if container.repository_exists?
      Gitlab::Git::Repository.new(
        source_storage_name,
        "#{container.disk_path}.git",
        nil,
        nil
      ).remove
    end
  end

  def wait_for_pushes(type)
    reference_counter = container.reference_counter(type: type)

    # Try for 30 seconds, polling every 10
    3.times do
      return true if reference_counter.value == 0

      sleep 10
    end

    false
  end
end
