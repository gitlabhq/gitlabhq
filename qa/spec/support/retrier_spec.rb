# frozen_string_literal: true

RSpec.describe QA::Support::Retrier do
  describe '.retry_until' do
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

    it 'sets raise_on_failure to true by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(raise_on_failure: true))

      subject.retry_until
    end

    it 'sets retry_on_exception to false by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(retry_on_exception: false))

      subject.retry_until
    end

    it 'allows logs to be silenced' do
      expect(subject).to receive(:repeat_until).with(hash_including(log: false))

      subject.retry_until(log: false)
    end

    it 'sets custom error message' do
      expect(subject).to receive(:repeat_until).with(hash_including(message: 'Custom message'))

      subject.retry_until(message: 'Custom message')
    end
  end

  describe '.retry_on_exception' do
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

    it 'allows logs to be silenced' do
      expect(subject).to receive(:repeat_until).with(hash_including(log: false))

      subject.retry_on_exception(log: false)
    end
  end
end
