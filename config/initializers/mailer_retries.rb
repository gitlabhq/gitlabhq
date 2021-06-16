# frozen_string_literal: true

class ActiveJob::QueueAdapters::SidekiqAdapter
  # With Sidekiq 6, we can do something like:
  # class ActionMailer::MailDeliveryJob
  #   sidekiq_options retry: 3
  # end
  #
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/329430
  raise "Update this monkey patch: #{__FILE__}" unless Sidekiq::VERSION == '5.2.9'

  def enqueue(job) #:nodoc:
    # Sidekiq::Client does not support symbols as keys
    job.provider_job_id = Sidekiq::Client.push \
      "class"   => JobWrapper,
      "wrapped" => job.class.to_s,
      "queue"   => job.queue_name,
      "args"    => [job.serialize],
      "retry"   => retry_for(job)
  end

  def enqueue_at(job, timestamp) #:nodoc:
    job.provider_job_id = Sidekiq::Client.push \
      "class"   => JobWrapper,
      "wrapped" => job.class.to_s,
      "queue"   => job.queue_name,
      "args"    => [job.serialize],
      "at"      => timestamp,
      "retry"   => retry_for(job)
  end

  private

  def retry_for(job)
    if job.queue_name == 'mailers'
      3
    else
      true
    end
  end
end
