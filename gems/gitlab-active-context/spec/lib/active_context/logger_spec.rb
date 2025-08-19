# frozen_string_literal: true

RSpec.describe ActiveContext::Logger do
  let(:mock_logger) { instance_double(::Logger) }

  before do
    allow(ActiveContext::Config).to receive(:logger).and_return(mock_logger)
  end

  describe '.debug' do
    it 'logs debug message with structured payload' do
      expect(mock_logger).to receive(:debug).with({
        'message' => 'test debug'
      })

      described_class.debug(message: 'test debug')
    end
  end

  describe '.info' do
    it 'logs info message with structured payload' do
      expect(mock_logger).to receive(:info).with({
        'event' => 'user_created'
      })

      described_class.info(event: 'user_created')
    end
  end

  describe '.warn' do
    it 'logs warning message with structured payload' do
      expect(mock_logger).to receive(:warn).with({
        'warning' => 'deprecated method used'
      })

      described_class.warn(warning: 'deprecated method used')
    end
  end

  describe '.error' do
    it 'logs error message with structured payload' do
      expect(mock_logger).to receive(:error).with({
        'error' => 'database connection failed'
      })

      described_class.error(error: 'database connection failed')
    end
  end

  describe '.fatal' do
    it 'logs fatal message with structured payload' do
      expect(mock_logger).to receive(:fatal).with({
        'fatal_error' => 'system shutdown'
      })

      described_class.fatal(fatal_error: 'system shutdown')
    end
  end

  describe '.exception' do
    let(:exception) { StandardError.new('Something went wrong') }
    let(:backtrace) { %w[line1 line2 line3] }

    before do
      allow(exception).to receive(:backtrace).and_return(backtrace)
    end

    it 'logs exception with structured payload' do
      expect(mock_logger).to receive(:error).with({
        'exception_class' => 'StandardError',
        'exception_message' => 'Something went wrong',
        'exception_backtrace' => backtrace
      })

      described_class.exception(exception)
    end

    it 'merges additional kwargs with exception data' do
      expect(mock_logger).to receive(:error).with({
        'exception_class' => 'StandardError',
        'exception_message' => 'Something went wrong',
        'exception_backtrace' => backtrace,
        'user_id' => 456,
        'context' => 'api_request'
      })

      described_class.exception(exception, user_id: 456, context: 'api_request')
    end

    it 'logs exception with class when explicitly provided' do
      expect(mock_logger).to receive(:error).with({
        'class' => 'PaymentService',
        'exception_class' => 'StandardError',
        'exception_message' => 'Something went wrong',
        'exception_backtrace' => backtrace
      })

      described_class.exception(exception, class: 'PaymentService')
    end

    it 'handles custom exception classes' do
      custom_exception = Class.new(StandardError).new('Custom error')
      allow(custom_exception).to receive(:backtrace).and_return(['custom_line'])

      expect(mock_logger).to receive(:error).with({
        'exception_class' => custom_exception.class.name,
        'exception_message' => 'Custom error',
        'exception_backtrace' => ['custom_line']
      })

      described_class.exception(custom_exception)
    end
  end

  describe '.retryable_exception' do
    let(:exception) { StandardError.new('Temporary failure') }
    let(:backtrace) { %w[retry_line1 retry_line2] }

    before do
      allow(exception).to receive(:backtrace).and_return(backtrace)
    end

    it 'logs retryable exception as warning with prefixed message' do
      expect(mock_logger).to receive(:warn).with({
        'exception_class' => 'StandardError',
        'exception_message' => 'Retryable Error occurred: Temporary failure',
        'exception_backtrace' => backtrace
      })

      described_class.retryable_exception(exception)
    end

    it 'merges additional kwargs with retryable exception data' do
      expect(mock_logger).to receive(:warn).with({
        'exception_class' => 'StandardError',
        'exception_message' => 'Retryable Error occurred: Temporary failure',
        'exception_backtrace' => backtrace,
        'retry_count' => 3,
        'max_retries' => 5
      })

      described_class.retryable_exception(exception, retry_count: 3, max_retries: 5)
    end

    it 'logs retryable exception with class when explicitly provided' do
      expect(mock_logger).to receive(:warn).with({
        'class' => 'ApiService',
        'exception_class' => 'StandardError',
        'exception_message' => 'Retryable Error occurred: Temporary failure',
        'exception_backtrace' => backtrace
      })

      described_class.retryable_exception(exception, class: 'ApiService')
    end
  end
end
