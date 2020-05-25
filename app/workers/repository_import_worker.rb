# frozen_string_literal: true

class RepositoryImportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include ExceptionBacktrace
  include ProjectStartImport
  include ProjectImportOptions

  feature_category :importers
  worker_has_external_dependencies!

  # technical debt: https://gitlab.com/gitlab-org/gitlab/issues/33991
  sidekiq_options memory_killer_memory_growth_kb: ENV.fetch('MEMORY_KILLER_REPOSITORY_IMPORT_WORKER_MEMORY_GROWTH_KB', 50).to_i
  sidekiq_options memory_killer_max_memory_growth_kb: ENV.fetch('MEMORY_KILLER_REPOSITORY_IMPORT_WORKER_MAX_MEMORY_GROWTH_KB', 300_000).to_i

  def perform(project_id)
    @project = Project.find(project_id)

    return unless start_import

    Gitlab::Metrics.add_event(:import_repository)

    service = Projects::ImportService.new(project, project.creator)
    result = service.execute

    # Some importers may perform their work asynchronously. In this case it's up
    # to those importers to mark the import process as complete.
    return if service.async?

    if result[:status] == :error
      fail_import(result[:message]) if template_import?

      raise result[:message]
    end

    project.after_import
  end

  private

  attr_reader :project

  def start_import
    return true if start(project.import_state)

    Gitlab::Import::Logger.info(
      message: 'Project was in inconsistent state while importing',
      project_full_path: project.full_path,
      project_import_status: project.import_status
    )

    false
  end

  def fail_import(message)
    project.import_state.mark_as_failed(message)
  end

  def template_import?
    project.gitlab_project_import?
  end
end

RepositoryImportWorker.prepend_if_ee('EE::RepositoryImportWorker')
