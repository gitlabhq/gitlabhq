class ProjectImportWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  sidekiq_options queue: :gitlab_shell

  def perform(current_user_id, tmp_file)
    current_user = User.find(current_user_id)

    project = Gitlab::ImportExport::ImportService.execute(archive_file: tmp_file, owner: current_user)

    # TODO: Move this to import service
    # if result[:status] == :error
    #   project.update(import_error: result[:message])
    #   project.import_fail
    #   return
    # end

    project.repository.after_import
    project.import_finish
  end
end
