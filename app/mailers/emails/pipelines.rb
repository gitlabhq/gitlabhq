# frozen_string_literal: true

module Emails
  module Pipelines
    def pipeline_success_email(pipeline, recipients)
      pipeline_mail(pipeline, recipients, 'succeeded')
    end

    def pipeline_failed_email(pipeline, recipients)
      pipeline_mail(pipeline, recipients, 'failed')
    end

    private

    def pipeline_mail(pipeline, recipients, status)
      @project = pipeline.project
      @pipeline = pipeline
      @merge_request = pipeline.all_merge_requests.first
      add_headers

      # We use bcc here because we don't want to generate these emails for a
      # thousand times. This could be potentially expensive in a loop, and
      # recipients would contain all project watchers so it could be a lot.
      mail(bcc: recipients,
           subject: pipeline_subject(status)) do |format|
        format.html { render layout: 'mailer' }
        format.text { render layout: 'mailer' }
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
      commit = [@pipeline.short_sha]
      commit << "in #{@merge_request.to_reference}" if @merge_request

      subject("Pipeline ##{@pipeline.id} has #{status} for #{@pipeline.source_ref}", commit.join(' '))
    end
  end
end
