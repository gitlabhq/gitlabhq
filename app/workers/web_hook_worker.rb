# frozen_string_literal: true

# Worker cannot be idempotent: https://gitlab.com/gitlab-org/gitlab/-/issues/218559
# rubocop:disable Scalability/IdempotentWorker
class WebHookWorker
  include ApplicationWorker

  feature_category :webhooks
  loggable_arguments 2, 3
  data_consistency :delayed
  sidekiq_options retry: 4, dead: false
  urgency :low

  worker_has_external_dependencies!

  def perform(hook_id, data, hook_name, params = {})
    hook = WebHook.find_by_id(hook_id)
    return unless hook

    data = Gitlab::WebHooks.prepare_data(data)
    params.symbolize_keys!

    # Before executing the hook, reapply any recursion detection UUID that was initially
    # present in the request header so the hook can pass this same header value in its request.
    Gitlab::WebHooks::RecursionDetection.set_request_uuid(params[:recursion_detection_request_uuid])

    idempotency_key = params[:idempotency_key]

    WebHookService.new(hook, data, hook_name, jid, idempotency_key: idempotency_key).execute.tap do |response|
      log_extra_metadata_on_done(:response_status, response.status)
      log_extra_metadata_on_done(:http_status, response[:http_status])
    end
  end
end
# rubocop:enable Scalability/IdempotentWorker
