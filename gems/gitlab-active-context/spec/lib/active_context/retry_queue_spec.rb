# frozen_string_literal: true

RSpec.describe ActiveContext::RetryQueue do
  it_behaves_like 'a retry chain stage',
    queue_name: 'retry_queue',
    delay: 5.minutes,
    next_queue: ActiveContext::SecondRetryQueue

  describe '.extra_preprocess_options' do
    it 'returns skip_missing_content: true so missing content is dropped rather than retried' do
      expect(described_class.extra_preprocess_options).to eq({
        skip_missing_content: true
      })
    end
  end
end
