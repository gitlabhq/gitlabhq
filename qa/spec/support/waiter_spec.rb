# frozen_string_literal: true

require 'logger'

describe QA::Support::Waiter do
  before do
    logger = ::Logger.new $stdout
    logger.level = ::Logger::DEBUG
    QA::Runtime::Logger.logger = logger
  end

  describe '.wait_until' do
    context 'when the condition is true' do
      it 'logs the start' do
        expect { subject.wait_until(max_duration: 0, raise_on_failure: false) { true } }
        .to output(/with wait_until: max_duration: 0; reload_page: ; sleep_interval: 0.1/).to_stdout_from_any_process
      end

      it 'logs the end' do
        expect { subject.wait_until(max_duration: 0, raise_on_failure: false) { true } }
        .to output(/ended wait_until$/).to_stdout_from_any_process
      end
    end

    context 'when the condition is false' do
      it 'logs the start' do
        expect { subject.wait_until(max_duration: 0, raise_on_failure: false) { false } }
        .to output(/with wait_until: max_duration: 0; reload_page: ; sleep_interval: 0.1/).to_stdout_from_any_process
      end

      it 'logs the end' do
        expect { subject.wait_until(max_duration: 0, raise_on_failure: false) { false } }
        .to output(/ended wait_until$/).to_stdout_from_any_process
      end
    end

    it 'sets max_duration to 60 by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(max_duration: 60))

      subject.wait_until
    end

    it 'sets sleep_interval to 0.1 by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(sleep_interval: 0.1))

      subject.wait_until
    end

    it 'sets raise_on_failure to false by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(raise_on_failure: false))

      subject.wait_until
    end

    it 'sets retry_on_exception to false by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(retry_on_exception: false))

      subject.wait_until
    end
  end
end
