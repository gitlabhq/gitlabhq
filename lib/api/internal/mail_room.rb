# frozen_string_literal: true

module API
  # This internal endpoint receives webhooks sent from the MailRoom component.
  # This component constantly listens to configured email accounts. When it
  # finds any incoming email or service desk email, it makes a POST request to
  # this endpoint. The target mailbox type is indicated in the request path.
  # The email raw content is attached to the request body.
  #
  # For more information, please visit https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/644
  module Internal
    class MailRoom < ::API::Base
      feature_category :service_desk

      format :json
      content_type :txt, 'text/plain'
      default_format :txt

      before do
        authenticate_gitlab_mailroom_request!
      end

      helpers do
        def authenticate_gitlab_mailroom_request!
          unauthorized! unless Gitlab::MailRoom::Authenticator.verify_api_request(headers, params[:mailbox_type])
        end
      end

      namespace 'internal' do
        namespace 'mail_room' do
          params do
            requires :mailbox_type, type: String,
              desc: 'The destination mailbox type configuration. Must either be incoming_email or service_desk_email'
          end
          post "/*mailbox_type" do
            worker = Gitlab::MailRoom.worker_for(params[:mailbox_type])
            raw = Gitlab::EncodingHelper.encode_utf8(request.body.read)
            begin
              worker.perform_async(raw)
            rescue Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError
              receiver = Gitlab::Email::Receiver.new(raw)
              reason = Gitlab::Email::FailureHandler.handle(receiver, Gitlab::Email::EmailTooLarge.new)

              status 400
              break { success: false, message: reason }
            end

            status 200
            { success: true }
          end
        end
      end
    end
  end
end
