# frozen_string_literal: true

class PipelineNotificationWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include PipelineQueue

  urgency :high
  worker_resource_boundary :cpu

  def perform(pipeline_id, args = {})
    case args
    when Hash
      args = args.with_indifferent_access
      ref_status = args[:ref_status]
      recipients = args[:recipients]
    else # TODO: backward compatible interface, can be removed in 12.10
      recipients = args
      ref_status = nil
    end

    pipeline = Ci::Pipeline.find_by_id(pipeline_id)
    return unless pipeline

    NotificationService.new.pipeline_finished(pipeline, ref_status: ref_status, recipients: recipients)
  end
end
