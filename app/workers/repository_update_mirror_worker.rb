class RepositoryUpdateMirrorWorker
  class UpdateMirrorError < StandardError; end

  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  LEASE_TIMEOUT = 300

  sidekiq_options queue: :gitlab_shell

  attr_accessor :project, :repository, :current_user

  def perform(project_id)
    begin
      return unless try_obtain_lease(project_id)

      @project = Project.find(project_id)
      @current_user = @project.mirror_user || @project.creator

      result = Projects::UpdateMirrorService.new(@project, @current_user).execute
      if result[:status] == :error
        project.mark_import_as_failed(result[:message])
        return
      end

      project.import_finish
    rescue => ex
      project.mark_import_as_failed("We're sorry, a temporary error occurred, please try again.")

      raise UpdateMirrorError, "#{ex.class}: #{Gitlab::UrlSanitizer.sanitize(ex.message)}"
    end
  end

  private

  def try_obtain_lease(project_id)
    # Using 5 minutes timeout based on the 95th percent of timings (currently max of 25 seconds)
    lease = ::Gitlab::ExclusiveLease.new("repository_update_mirror:#{project_id}", timeout: LEASE_TIMEOUT)
    lease.try_obtain
  end
end
