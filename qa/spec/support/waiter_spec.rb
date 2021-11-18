# frozen_string_literal: true

RSpec.describe QA::Support::Waiter do
  describe '.wait_until' do
    it 'allows logs to be silenced' do
      expect(subject).to receive(:repeat_until).with(hash_including(log: false))

      subject.wait_until(log: false)
    end

    it 'sets max_duration to 60 by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(max_duration: 60))

      subject.wait_until
    end

    it 'sets sleep_interval to 0.1 by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(sleep_interval: 0.1))

      subject.wait_until
    end

    it 'sets raise_on_failure to true by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(raise_on_failure: true))

      subject.wait_until
    end

    it 'sets retry_on_exception to false by default' do
      expect(subject).to receive(:repeat_until).with(hash_including(retry_on_exception: false))

      subject.wait_until
    end
  end
end
