# frozen_string_literal: true

module AutoDevops
  class DisableWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include AutoDevopsQueue

    def perform(pipeline_id)
      pipeline = Ci::Pipeline.find(pipeline_id)
      project = pipeline.project

      send_notification_email(pipeline, project) if disable_service(project).execute
    end

    private

    def disable_service(project)
      Projects::AutoDevops::DisableService.new(project)
    end

    def send_notification_email(pipeline, project)
      recipients = email_receivers_for(pipeline, project)

      return unless recipients.any?

      NotificationService.new.autodevops_disabled(pipeline, recipients)
    end

    def email_receivers_for(pipeline, project)
      recipients = [pipeline.user&.email]
      recipients << project.owner.email unless project.group
      recipients.uniq.compact
    end
  end
end
