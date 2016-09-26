module Emails
  module Pipelines
    def pipeline_success_email(pipeline, to)
      pipeline_mail(pipeline, to, 'succeeded')
    end

    def pipeline_failed_email(pipeline, to)
      pipeline_mail(pipeline, to, 'failed')
    end

    private

    def pipeline_mail(pipeline, to, status)
      @project = pipeline.project
      @pipeline = pipeline
      @merge_request = @project.merge_requests.opened.
        find_by(source_project: @project,
                source_branch: @pipeline.ref,
                target_branch: @project.default_branch)
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
