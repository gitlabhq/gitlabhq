# frozen_string_literal: true

module UpdateRepositoryStorageMethods
  include Gitlab::Utils::StrongMemoize

  Error = Class.new(StandardError)

  attr_reader :repository_storage_move
  delegate :container, :source_storage_name, :destination_storage_name, to: :repository_storage_move

  def initialize(repository_storage_move)
    @repository_storage_move = repository_storage_move
  end

  def execute
    repository_storage_move.with_lock do
      return ServiceResponse.success unless repository_storage_move.scheduled? # rubocop:disable Cop/AvoidReturnFromBlocks

      repository_storage_move.start!
    end

    mirror_repositories unless same_filesystem?

    repository_storage_move.transaction do
      repository_storage_move.finish_replication!

      track_repository(destination_storage_name)
    end

    unless same_filesystem?
      remove_old_paths
      enqueue_housekeeping
    end

    repository_storage_move.finish_cleanup!

    ServiceResponse.success
  rescue StandardError => e
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

  def mirror_repository(type:)
    unless wait_for_pushes(type)
      raise Error, s_('UpdateRepositoryStorage|Timeout waiting for %{type} repository pushes') % { type: type.name }
    end

    repository = type.repository_for(container)
    full_path = repository.full_path
    raw_repository = repository.raw
    checksum = repository.checksum

    # Initialize a git repository on the target path
    new_repository = Gitlab::Git::Repository.new(
      destination_storage_name,
      raw_repository.relative_path,
      raw_repository.gl_repository,
      full_path
    )

    new_repository.replicate(raw_repository)
    new_checksum = new_repository.checksum

    if checksum != new_checksum
      raise Error, s_('UpdateRepositoryStorage|Failed to verify %{type} repository checksum from %{old} to %{new}') % { type: type.name, old: checksum, new: new_checksum }
    end
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

  def enqueue_housekeeping
    # no-op
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
