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

    it 'defaults to :unexpected handling and logs as an error with the raw message' do
      expect(mock_logger).to receive(:error).with({
        'exception_class' => 'StandardError',
        'exception_message' => 'Something went wrong',
        'exception_backtrace' => backtrace,
        'handling' => 'unexpected'
      })

      described_class.exception(exception)
    end

    it 'merges additional kwargs with exception data' do
      expect(mock_logger).to receive(:error).with({
        'exception_class' => 'StandardError',
        'exception_message' => 'Something went wrong',
        'exception_backtrace' => backtrace,
        'handling' => 'unexpected',
        'user_id' => 456,
        'context' => 'api_request'
      })

      described_class.exception(exception, user_id: 456, context: 'api_request')
    end

    it 'logs exception with class when explicitly provided' do
      expect(mock_logger).to receive(:error).with({
        'class_name' => 'PaymentService',
        'exception_class' => 'StandardError',
        'exception_message' => 'Something went wrong',
        'exception_backtrace' => backtrace,
        'handling' => 'unexpected'
      })

      described_class.exception(exception, class_name: 'PaymentService')
    end

    it 'handles custom exception classes' do
      custom_exception = Class.new(StandardError).new('Custom error')
      allow(custom_exception).to receive(:backtrace).and_return(['custom_line'])

      expect(mock_logger).to receive(:error).with({
        'exception_class' => custom_exception.class.name,
        'exception_message' => 'Custom error',
        'exception_backtrace' => ['custom_line'],
        'handling' => 'unexpected'
      })

      described_class.exception(custom_exception)
    end

    context 'when handling: :retryable is given' do
      it 'logs as a warning with the raw message, no prefix' do
        expect(mock_logger).to receive(:warn).with({
          'exception_class' => 'StandardError',
          'exception_message' => 'Something went wrong',
          'exception_backtrace' => backtrace,
          'handling' => 'retryable'
        })

        described_class.exception(exception, handling: :retryable)
      end
    end

    context 'when handling: :infinite_retry is given' do
      it 'logs as a warning' do
        expect(mock_logger).to receive(:warn).with({
          'exception_class' => 'StandardError',
          'exception_message' => 'Something went wrong',
          'exception_backtrace' => backtrace,
          'handling' => 'infinite_retry'
        })

        described_class.exception(exception, handling: :infinite_retry)
      end
    end

    context 'when handling: :skipped is given' do
      it 'logs as a warning' do
        expect(mock_logger).to receive(:warn).with({
          'exception_class' => 'StandardError',
          'exception_message' => 'Something went wrong',
          'exception_backtrace' => backtrace,
          'handling' => 'skipped'
        })

        described_class.exception(exception, handling: :skipped)
      end
    end

    context 'when handling is not one of the known categories' do
      it 'raises instead of silently logging under the wrong severity' do
        expect { described_class.exception(exception, handling: :bogus) }.to raise_error(KeyError)
      end
    end
  end
end
