# frozen_string_literal: true

RSpec.describe ActiveContext::ThirdRetryQueue do
  it_behaves_like 'a retry chain stage',
    queue_name: 'third_retry_queue',
    delay: 2.hours,
    next_queue: ActiveContext::FourthRetryQueue
end
