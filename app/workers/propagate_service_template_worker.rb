# frozen_string_literal: true

# No longer in use https://gitlab.com/groups/gitlab-org/-/epics/5672
# To be removed https://gitlab.com/gitlab-org/gitlab/-/issues/335178
class PropagateServiceTemplateWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :integrations

  LEASE_TIMEOUT = 4.hours.to_i

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(template_id)
    return unless try_obtain_lease_for(template_id)

    Admin::PropagateServiceTemplate.propagate(Integration.find_by(id: template_id))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def try_obtain_lease_for(template_id)
    Gitlab::ExclusiveLease
      .new("propagate_service_template_worker:#{template_id}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end
end
