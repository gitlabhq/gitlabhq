require 'webpush'

class PipelineWebpushWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      Webpush.payload_send(
        endpoint: "https://fcm.googleapis.com/fcm/send/eYrtp_NOfZY:APA91bHxoXNgTmEJE47VUhvLrjyb72BhjvRZ7yZosPoPBJtRMLzoWqsbjPIdjiB3ECF-VCbMiqsSrbSiuWXifEaVw0UyhhKm7cu2V0Ip9F7XjRSKMI5PLTa2frSO2dXo1Aibttw7wIPn",
        message: "#{pipeline_id} has updated",
        p256dh: "BObyHSrRFRtKkZBpCWb-bB7K3DZQOOcu-fZzJ851HgXyGyZZagpHvx3S0-dxucNUcKSxMOQ4i3VFzH6KIiYH3Bs=",
        auth: "-BT3PjBL64u8u-RM2XVnpw==",
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
