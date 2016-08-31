module Emails
  module Pipelines
    def pipeline_succeeded_email(params, to)
      pipeline_mail(params, to, 'succeeded') # TODO: missing template
    end

    def pipeline_failed_email(params, to)
      pipeline_mail(params, to, 'failed') # TODO: missing template
    end

    private

    def pipeline_mail(params, to, status)
      @project = params.project
      @pipeline = params.pipeline
      add_headers

      mail(to: to, subject: pipeline_subject(status))
    end

    def add_headers
      add_project_headers
      add_pipeline_headers
    end

    def add_pipeline_headers
      headers['X-GitLab-Pipeline-Id'] = @pipeline.id
      headers['X-GitLab-Pipeline-Ref'] = @pipeline.ref
      headers['X-GitLab-Pipeline-Status'] = @pipeline.status
    end

    def pipeline_subject(status)
      subject(
        "Pipeline #{status} for #{@project.name}", @pipeline.short_sha)
    end
  end
end
