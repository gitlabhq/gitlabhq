# frozen_string_literal: true

module Emails
  module PipelineSchedules
    def pipeline_schedule_owner_unavailable_email(schedule, recipient)
      raise ArgumentError if recipient.is_a?(Array)

      @schedule = schedule

      email_with_layout(
        to: recipient.notification_email_or_default,
        subject: subject(assign_new_owner_subject(schedule.description)))
    end

    private

    def assign_new_owner_subject(description)
      "Take ownership of the pipeline schedule: #{description}"
    end
  end
end
