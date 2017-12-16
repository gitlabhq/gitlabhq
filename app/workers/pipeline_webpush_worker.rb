require 'webpush'

class PipelineWebpushWorker
  include ApplicationWorker
  include PipelineQueue
  include WebpushHelper

  queue_namespace :pipeline_default

  def perform(pipeline_id, subscribers)
    Ci::Pipeline.find(pipeline_id).try do |pipeline|
      subscribers.each do |subscriber|
        Webpush.payload_send(
          message: "#{pipeline_id} has updated",
          endpoint: subscriber.webpush_endpoint,
          p256dh: subscriber.webpush_p256dh,
          auth: subscriber.webpush_auth,
          vapid: vapid_credentials
        )
      end
    end
  end
end
