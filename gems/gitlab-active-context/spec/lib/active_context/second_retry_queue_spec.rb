# frozen_string_literal: true

RSpec.describe ActiveContext::SecondRetryQueue do
  it_behaves_like 'a retry chain stage',
    queue_name: 'second_retry_queue',
    delay: 30.minutes,
    next_queue: ActiveContext::ThirdRetryQueue
end
