# frozen_string_literal: true

# In case mailer jobs are enqueued using the enqueue_all method,
# we need to ensure our router handles routing the job to the right Sidekiq pool.
#
# We need to set the following up to override the ActiveJob adapater
# so as to ensure that mailer jobs are enqueued in a shard-aware manner.
#
# The upstream implementation is:
# https://github.com/rails/rails/blob/v8.0.0/activejob/lib/active_job/queue_adapters/sidekiq_adapter.rb#L35

if Gem::Version.new(Rails.gem_version) >= Gem::Version.new('8.1')
  raise 'New version of Rails detected, please remove or update this patch'
end

module ActiveJob
  module QueueAdapters
    module ActiveJobShardSupport
      def enqueue_all(jobs)
        Gitlab::SidekiqSharding::Router.route(ActionMailer::MailDeliveryJob) do
          super(jobs)
        end
      end
    end

    # This adapter is used in development & production environments.
    class SidekiqAdapter
      prepend ActiveJobShardSupport
    end
  end
end
