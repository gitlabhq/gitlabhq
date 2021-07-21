# frozen_string_literal: true

class RepositoryForkWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ProjectStartImport
  include ProjectImportOptions

  feature_category :source_code_management

  def perform(*args)
    target_project_id = args.shift
    target_project = Project.find(target_project_id)

    source_project = target_project.forked_from_project
    unless source_project
      return target_project.import_state.mark_as_failed(_('Source project cannot be found.'))
    end

    fork_repository(target_project, source_project)
  end

  private

  def fork_repository(target_project, source_project)
    return unless start_fork(target_project)

    Gitlab::Metrics.add_event(:fork_repository)

    gitaly_fork!(source_project, target_project)
    link_lfs_objects(source_project, target_project)
    target_project.after_import
  end

  def start_fork(project)
    return true if start(project.import_state)

    Gitlab::AppLogger.info("Project #{project.full_path} was in inconsistent state (#{project.import_status}) while forking.")
    false
  end

  def gitaly_fork!(source_project, target_project)
    source_repo = source_project.repository.raw
    target_repo = target_project.repository.raw

    ::Gitlab::GitalyClient::RepositoryService.new(target_repo).fork_repository(source_repo)
  rescue GRPC::BadStatus => e
    Gitlab::ErrorTracking.track_exception(e, source_project_id: source_project.id, target_project_id: target_project.id)

    raise_fork_failure(source_project, target_project, 'Failed to create fork repository')
  end

  def link_lfs_objects(source_project, target_project)
    Projects::LfsPointers::LfsLinkService
        .new(target_project)
        .execute(source_project.lfs_objects_oids)
  rescue Projects::LfsPointers::LfsLinkService::TooManyOidsError
    raise_fork_failure(
      source_project,
      target_project,
      'Source project has too many LFS objects'
    )
  end

  def raise_fork_failure(source_project, target_project, reason)
    raise "Unable to fork project #{target_project.id} for repository #{source_project.disk_path} -> #{target_project.disk_path}: #{reason}"
  end
end
