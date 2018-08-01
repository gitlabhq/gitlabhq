module EE
  module RepositoryImportWorker
    extend ::Gitlab::Utils::Override

    override :perform
    def perform(project_id)
      super

      # Explicitly enqueue mirror for update so
      # that upstream remote is created and fetched
      project.force_import_job! if project.mirror?
    end

    override :template_import?
    def template_import?
      super || project.gitlab_custom_project_template_import?
    end
  end
end
