# frozen_string_literal: true

module Projects
  class ExportJobFinder
    InvalidExportJobStatusError = Class.new(StandardError)
    attr_reader :project, :user, :params

    def initialize(project, user, params = {})
      @project = project
      @user = user
      @params = params
    end

    def execute
      export_jobs = project.export_jobs.by_user_id(user.id)
      by_status(export_jobs)
    end

    private

    def by_status(export_jobs)
      return export_jobs unless params[:status]

      unless ProjectExportJob.state_machines[:status].states.map(&:name).include?(params[:status])
        raise InvalidExportJobStatusError, 'Invalid export job status'
      end

      export_jobs.with_status(params[:status])
    end
  end
end
