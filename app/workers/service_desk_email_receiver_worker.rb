# frozen_string_literal: true

class ServiceDeskEmailReceiverWorker < EmailReceiverWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :service_desk
  sidekiq_options retry: 3

  def should_perform?
    ::Gitlab::ServiceDeskEmail.enabled?
  end

  def receiver
    @receiver ||= Gitlab::Email::ServiceDeskReceiver.new(raw)
  end
end
