# frozen_string_literal: true

class RepositoryForkWorker
  include ApplicationWorker
  include Gitlab::ShellAdapter
  include ProjectStartImport
  include ProjectImportOptions

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

    result = gitlab_shell.fork_repository(source_project, target_project)

    raise "Unable to fork project #{target_project.id} for repository #{source_project.disk_path} -> #{target_project.disk_path}" unless result

    target_project.after_import
  end

  def start_fork(project)
    return true if start(project.import_state)

    Rails.logger.info("Project #{project.full_path} was in inconsistent state (#{project.import_status}) while forking.") # rubocop:disable Gitlab/RailsLogger
    false
  end
end
