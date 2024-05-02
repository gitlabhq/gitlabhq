# frozen_string_literal: true

# As discussed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148637#note_1850247875,
# Rails 7.1 introduces enqueue_all which is not covered in this patch.
if Gem::Version.new(Rails.gem_version) >= Gem::Version.new('7.1')
  raise 'New version of Rails detected, please remove or update this patch'
end

# We deliver emails using the `deliver_later` method and it uses ActiveJob
# under the hood, which later processes the email via the defined ActiveJob adapter's `enqueue` method.
# For GitLab, the ActiveJob adapter is Sidekiq (in development and production environments).
# We need to set the following up to override the ActiveJob adapater
# so as to ensure that mailer jobs are enqueued in a shard-aware manner.
module ActiveJob
  module QueueAdapters
    module ActiveJobShardSupport
      %i[enqueue enqueue_at].each do |name|
        define_method(name) do |*args|
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
