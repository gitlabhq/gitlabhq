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
      @merge_request = pipeline.merge_requests_with_active_first.first
      add_headers

      mail(to: to, subject: pipeline_subject(status), skip_premailer: true) do |format|
        format.html { render layout: false }
        format.text
      end
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
      commit = @pipeline.short_sha
      commit << " in #{@merge_request.to_reference}" if @merge_request

      subject("Pipeline ##{@pipeline.id} has #{status} for #{@pipeline.ref}", commit)
    end
  end
end
