# frozen_string_literal: true

class EmailReceiverWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :team_planning
  urgency :high
  weight 2

  attr_accessor :raw

  def perform(raw)
    return unless should_perform?

    @raw = raw
    execute_receiver
  end

  def should_perform?
    Gitlab::Email::IncomingEmail.enabled?
  end

  private

  def execute_receiver
    receiver.execute
    log_success
  rescue StandardError => e
    log_error(e)
    handle_failure(e)
  end

  def receiver
    @receiver ||= Gitlab::Email::Receiver.new(raw)
  end

  def logger
    Sidekiq.logger
  end

  def log_success
    logger.info(build_message('Successfully processed message', receiver.mail_metadata))
  end

  def log_error(error)
    payload =
      case error
      # Unparsable e-mails don't have metadata we can use
      when Gitlab::Email::EmailUnparsableError, Gitlab::Email::EmptyEmailError
        {}
      else
        mail_metadata
      end

    # We don't need the backtrace and more details if the e-mail couldn't be processed
    if error.is_a?(Gitlab::Email::ProcessingError)
      payload['exception.class'] = error.class.name
    else
      Gitlab::ExceptionLogFormatter.format!(error, payload)
      Gitlab::ErrorTracking.track_exception(error)
    end

    logger.error(build_message('Error processing message', payload))
  end

  def build_message(message, params = {})
    {
      class: self.class.name,
      Labkit::Correlation::CorrelationId::LOG_KEY => Labkit::Correlation::CorrelationId.current_id,
      message: message
    }.merge(params)
  end

  def mail_metadata
    receiver.mail_metadata
  rescue StandardError => e
    # We should never get here as long as we check EmailUnparsableError, but
    # let's be defensive in case we did something wrong.
    Gitlab::ErrorTracking.track_exception(e)
    {}
  end

  def handle_failure(error)
    return unless raw.present?

    Gitlab::Email::FailureHandler.handle(receiver, error)
  end
end
