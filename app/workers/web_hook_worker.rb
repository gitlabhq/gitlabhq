# frozen_string_literal: true

# Worker cannot be idempotent: https://gitlab.com/gitlab-org/gitlab/-/issues/218559
# rubocop:disable Scalability/IdempotentWorker
class WebHookWorker
  include ApplicationWorker

  feature_category :integrations
  worker_has_external_dependencies!
  loggable_arguments 2
  data_consistency :delayed

  sidekiq_options retry: 4, dead: false

  def perform(hook_id, data, hook_name)
    hook = WebHook.find(hook_id)
    data = data.with_indifferent_access

    WebHookService.new(hook, data, hook_name, jid).execute
  end
end
# rubocop:enable Scalability/IdempotentWorker
