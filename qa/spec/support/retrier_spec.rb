# frozen_string_literal: true

require 'logger'
require 'timecop'

describe QA::Support::Retrier do
  before do
    logger = ::Logger.new $stdout
    logger.level = ::Logger::DEBUG
    QA::Runtime::Logger.logger = logger
  end

  describe '.retry_until' do
    context 'when the condition is true' do
      it 'logs max attempts (3 by default)' do
        expect { subject.retry_until { true } }
          .to output(/with retry_until: max_attempts: 3; reload_page: ; sleep_interval: 0; raise_on_failure: false; retry_on_exception: false/).to_stdout_from_any_process
      end

      it 'logs max duration' do
        expect { subject.retry_until(max_duration: 1) { true } }
          .to output(/with retry_until: max_duration: 1; reload_page: ; sleep_interval: 0; raise_on_failure: false; retry_on_exception: false/).to_stdout_from_any_process
      end

      it 'logs the end' do
        expect { subject.retry_until { true } }
        .to output(/ended retry_until$/).to_stdout_from_any_process
      end
    end

    context 'when the condition is false' do
      it 'logs the start' do
        expect { subject.retry_until(max_duration: 0) { false } }
          .to output(/with retry_until: max_duration: 0; reload_page: ; sleep_interval: 0; raise_on_failure: false; retry_on_exception: false/).to_stdout_from_any_process
      end

      it 'logs the end' do
        expect { subject.retry_until(max_duration: 0) { false } }
        .to output(/ended retry_until$/).to_stdout_from_any_process
      end
    end

    context 'when max_duration and max_attempts are nil' do
      it 'sets max attempts to 3 by default' do
        expect(subject).to receive(:repeat_until).with(hash_including(max_attempts: 3))

        subject.retry_until
      end
    end

    it 'sets sleep_interval to 0 by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(sleep_interval: 0))

      subject.retry_until
    end

    it 'sets raise_on_failure to false by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(raise_on_failure: false))

      subject.retry_until
    end

    it 'sets retry_on_exception to false by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(retry_on_exception: false))

      subject.retry_until
    end
  end

  describe '.retry_on_exception' do
    context 'when the condition is true' do
      it 'logs max_attempts, reload_page, and sleep_interval parameters' do
        expect { subject.retry_on_exception(max_attempts: 1, reload_page: nil, sleep_interval: 0) { true } }
          .to output(/with retry_on_exception: max_attempts: 1; reload_page: ; sleep_interval: 0/).to_stdout_from_any_process
      end

      it 'logs the end' do
        expect { subject.retry_on_exception(max_attempts: 1, reload_page: nil, sleep_interval: 0) { true } }
        .to output(/ended retry_on_exception$/).to_stdout_from_any_process
      end
    end

    context 'when the condition is false' do
      it 'logs the start' do
        expect { subject.retry_on_exception(max_attempts: 1, reload_page: nil, sleep_interval: 0) { false } }
          .to output(/with retry_on_exception: max_attempts: 1; reload_page: ; sleep_interval: 0/).to_stdout_from_any_process
      end

      it 'logs the end' do
        expect { subject.retry_on_exception(max_attempts: 1, reload_page: nil, sleep_interval: 0) { false } }
        .to output(/ended retry_on_exception$/).to_stdout_from_any_process
      end
    end

    it 'does not repeat if no exception is raised' do
      loop_counter = 0
      return_value = "test passed"

      expect(
        subject.retry_on_exception(max_attempts: 2) do
          loop_counter += 1
          return_value
        end
      ).to eq(return_value)
      expect(loop_counter).to eq(1)
    end

    it 'sets retry_on_exception to true' do
      expect(subject).to receive(:repeat_until).with(hash_including(retry_on_exception: true))

      subject.retry_on_exception
    end

    it 'sets max_attempts to 3 by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(max_attempts: 3))

      subject.retry_on_exception
    end

    it 'sets sleep_interval to 0.5 by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(sleep_interval: 0.5))

      subject.retry_on_exception
    end
  end
end
