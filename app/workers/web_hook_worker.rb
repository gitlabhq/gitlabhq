# frozen_string_literal: true

# Worker cannot be idempotent: https://gitlab.com/gitlab-org/gitlab/-/issues/218559
# rubocop:disable Scalability/IdempotentWorker
class WebHookWorker
  include ApplicationWorker

  feature_category :integrations
  loggable_arguments 2, 3
  data_consistency :delayed
  sidekiq_options retry: 4, dead: false
  urgency :low

  worker_has_external_dependencies!

  # Webhook recursion detection properties may be passed through the `data` arg.
  # This will be migrated to the `params` arg over the next few releases.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/347389.
  def perform(hook_id, data, hook_name, params = {})
    hook = WebHook.find_by_id(hook_id)
    return unless hook

    data = data.with_indifferent_access
    params.symbolize_keys!

    # TODO: Remove in 14.9 https://gitlab.com/gitlab-org/gitlab/-/issues/347389
    params[:recursion_detection_request_uuid] ||= data.delete(:_gitlab_recursion_detection_request_uuid)

    # Before executing the hook, reapply any recursion detection UUID that was initially
    # present in the request header so the hook can pass this same header value in its request.
    Gitlab::WebHooks::RecursionDetection.set_request_uuid(params[:recursion_detection_request_uuid])

    WebHookService.new(hook, data, hook_name, jid).execute
  end
end
# rubocop:enable Scalability/IdempotentWorker
