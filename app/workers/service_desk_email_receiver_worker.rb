# frozen_string_literal: true

class ServiceDeskEmailReceiverWorker < EmailReceiverWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  feature_category :service_desk
  sidekiq_options retry: 3

  # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1087#jobs-written-to-redis-without-passing-through-the-application
  tags :needs_own_queue

  def should_perform?
    ::Gitlab::ServiceDeskEmail.enabled?
  end

  def receiver
    @receiver ||= Gitlab::Email::ServiceDeskReceiver.new(raw)
  end
end
