# frozen_string_literal: true

# We deliver emails using the `deliver_later` method and it uses ActiveJob
# under the hood, which later processes the email via the defined ActiveJob adapter's `enqueue` method.
# For GitLab, the ActiveJob adapter is Sidekiq (in development and production environments).
#
# We need to set the following up to override the ActiveJob adapater
# so as to ensure that mailer jobs are enqueued in a shard-aware manner.

if Gem::Version.new(Rails.gem_version) >= Gem::Version.new('7.2')
  raise 'New version of Rails detected, please remove or update this patch'
end

module ActiveJob
  module QueueAdapters
    module ActiveJobShardSupport
      if ::Gitlab.next_rails?
        def enqueue_all(jobs)
          Gitlab::SidekiqSharding::Router.route(ActionMailer::MailDeliveryJob) do
            super(jobs)
          end
        end
      end

      %i[enqueue enqueue_at].each do |name|
        define_method(name) do |*args|
          return super(*args) if ::Gitlab.next_rails?

          Gitlab::SidekiqSharding::Router.route(ActionMailer::MailDeliveryJob) do
            super(*args)
          end
        end
      end
    end

    # This adapter is used in development & production environments.
    class SidekiqAdapter
      prepend ActiveJobShardSupport
    end
  end
end
