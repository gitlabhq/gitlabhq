# frozen_string_literal: true

module Projects
  class ExportJobFinder
    InvalidExportJobStatusError = Class.new(StandardError)
    attr_reader :project, :params

    def initialize(project, params = {})
      @project = project
      @params = params
    end

    def execute
      export_jobs = project.export_jobs
      by_status(export_jobs)
    end

    private

    def by_status(export_jobs)
      return export_jobs unless params[:status]
      raise InvalidExportJobStatusError, 'Invalid export job status' unless ProjectExportJob.state_machines[:status].states.map(&:name).include?(params[:status])

      export_jobs.with_status(params[:status])
    end
  end
end
