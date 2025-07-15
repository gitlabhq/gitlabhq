# frozen_string_literal: true

class RepositoryImportWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always
  include ExceptionBacktrace
  include ProjectStartImport
  include Sidekiq::InterruptionsExhausted

  feature_category :importers
  worker_has_external_dependencies!
  # Do not retry on Import/Export until https://gitlab.com/gitlab-org/gitlab/-/issues/16812 is solved.
  sidekiq_options retry: false, dead: false
  sidekiq_options status_expiration: Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION
  worker_resource_boundary :memory

  sidekiq_interruptions_exhausted do |job|
    new.perform_failure(job['args'].first)
  end

  def perform(project_id)
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464677')

    @project = Project.find_by_id(project_id)
    return if project.nil? || !start_import?

    Gitlab::Metrics.add_event(:import_repository)

    service = Projects::ImportService.new(project, project.creator)
    result = service.execute

    # Some importers may perform their work asynchronously. In this case it's up
    # to those importers to mark the import process as complete.
    return if service.async?

    if result[:status] == :error
      project.reset_counters_and_iids
      fail_import(result[:message])
    else
      project.after_import
    end
  end

  def perform_failure(project_id)
    @project = Project.find_by_id(project_id)
    import_export_upload = @project.import_export_uploads.find_by_user_id(project.creator.id)

    fail_import('Import process reached the maximum number of interruptions')

    ::Gitlab::Import::RemoveImportFileWorker.perform_async(import_export_upload.id)
  end

  private

  attr_reader :project

  def start_import?
    return true if start(project.import_state)

    ::Import::Framework::Logger.info(
      message: 'Project was in inconsistent state while importing',
      project_full_path: project.full_path,
      project_import_status: project.import_status
    )

    false
  end

  def fail_import(message)
    project.import_state.mark_as_failed(message)
  end
end

RepositoryImportWorker.prepend_mod_with('RepositoryImportWorker')
