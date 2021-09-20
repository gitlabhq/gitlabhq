# frozen_string_literal: true

class ServiceDeskEmailReceiverWorker < EmailReceiverWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  feature_category :service_desk
  urgency :high
  sidekiq_options retry: 3

  # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1263
  tags :needs_own_queue

  def should_perform?
    ::Gitlab::ServiceDeskEmail.enabled?
  end

  def receiver
    @receiver ||= Gitlab::Email::ServiceDeskReceiver.new(raw)
  end
end
