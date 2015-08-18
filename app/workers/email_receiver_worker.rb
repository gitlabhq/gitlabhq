class EmailReceiverWorker
  include Sidekiq::Worker

  sidekiq_options queue: :incoming_email

  def perform(raw)
    return unless Gitlab.config.reply_by_email.enabled

    # begin
      Gitlab::EmailReceiver.new(raw).process
    # rescue => e
    #   handle_failure(raw, e)
    # end
  end

  private

  def handle_failure(raw, e)
    # TODO: Handle better.
    Rails.logger.warn("Email can not be processed: #{e}\n\n#{raw}")
  end
end
