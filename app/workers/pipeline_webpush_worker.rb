require 'webpush'

class PipelineWebpushWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_default

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      Webpush.payload_send(
        endpoint: "https://fcm.googleapis.com/fcm/send/d7Ogvwj1QcA:APA91bFPDYAhgwYWZjl8u7OFGeyuteanutDQMNo1dM6dZvuo1LIxCinHcEkoYfmmjglv59ZalYTYuRAzKuOTG12jH_3guVs_L2IHpUroh4q4r6ae1oc6lw8Ie1esK1wAyudyWJSejAKc",
        message: "#{pipeline_id} has updated",
        p256dh: "BE9xULW-AeMf_4oUxHY0cLLjNPmxgjxMKbZmA8b6HVBYr1aUTJHoYmMmCvzF2sOs_i5nfxJISWBiaqFEEqBfuS8=",
        auth: "EN_d1ZuVtfhTW01Gb83d_g==",
        vapid: vapid_credentials
      )
    end
  end

  private

  def vapid_credentials
    {
      subject: "mailto:lbennett@gitlab.com",
      public_key: "BMV-YKtRZpthj5tS1sW4BBaNEqZ67gAQYH_lFLR156QD1pi4TJGZGw46rCBFbFoqV2cMNI6ilD9PZ3DPPt2nEdI",
      private_key: "3Ex0EQD-67zli0YM4SioxmYxbYvyiT1aRCTLZombOy4"
    }
  end

end
