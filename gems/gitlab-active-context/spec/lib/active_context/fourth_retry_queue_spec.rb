# frozen_string_literal: true

RSpec.describe ActiveContext::FourthRetryQueue do
  it_behaves_like 'a retry chain stage',
    queue_name: 'fourth_retry_queue',
    delay: 8.hours,
    next_queue: ActiveContext::DeadQueue
end
