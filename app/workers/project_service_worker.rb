# frozen_string_literal: true

# This worker was renamed in 15.1, we can delete it in 15.2.
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/364112
#
# rubocop: disable Gitlab/NamespacedClass
# rubocop: disable Scalability/IdempotentWorker
class ProjectServiceWorker < Integrations::ExecuteWorker
  data_consistency :always
  sidekiq_options retry: 3
  sidekiq_options dead: false
  feature_category :integrations
  urgency :low

  worker_has_external_dependencies!
end
