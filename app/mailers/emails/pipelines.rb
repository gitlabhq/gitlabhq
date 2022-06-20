# frozen_string_literal: true

module Emails
  module Pipelines
    def pipeline_success_email(pipeline, recipient)
      pipeline_mail(pipeline, recipient, 'Successful')
    end

    def pipeline_failed_email(pipeline, recipient)
      pipeline_mail(pipeline, recipient, 'Failed')
    end

    def pipeline_fixed_email(pipeline, recipient)
      pipeline_mail(pipeline, recipient, 'Fixed')
    end

    private

    def pipeline_mail(pipeline, recipient, status)
      raise ArgumentError if recipient.is_a?(Array)

      @project = pipeline.project
      @pipeline = pipeline

      @merge_request = if pipeline.merge_request?
                         pipeline.merge_request
                       else
                         pipeline.merge_requests_as_head_pipeline.first
                       end

      add_headers

      email_with_layout(
        to: recipient,
        subject: subject(pipeline_subject(status)))
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
      subject = []

      subject << "#{status} pipeline for #{@pipeline.source_ref}"
      subject << @pipeline.short_sha

      subject.join(' | ')
    end
  end
end
