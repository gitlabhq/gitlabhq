# frozen_string_literal: true

# Module to support correlation_id and additional job details.
module Gitlab
  module Marginalia
    module Comment
      private

      def jid
        bg_job["jid"] if bg_job.present?
      end

      def job_class
        bg_job["class"] if bg_job.present?
      end

      def correlation_id
        if bg_job.present?
          bg_job["correlation_id"]
        else
          Labkit::Correlation::CorrelationId.current_id
        end
      end

      def bg_job
        job = ::Marginalia::Comment.marginalia_job

        # We are using 'Marginalia::SidekiqInstrumentation' which does not support 'ActiveJob::Base'.
        # Gitlab also uses 'ActionMailer::DeliveryJob' which inherits from ActiveJob::Base.
        # So below condition is used to return metadata for such jobs.
        if job && job.is_a?(ActionMailer::DeliveryJob)
          {
            "class" => job.arguments.first,
            "jid"   => job.job_id
          }
        else
          job
        end
      end
    end
  end
end
