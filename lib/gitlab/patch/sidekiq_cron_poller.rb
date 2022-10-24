# frozen_string_literal: true

# Patch to address https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1932
# It restores the behavior of `poll_internal_average` to the one from Sidekiq 6.4.2
# (see https://github.com/mperham/sidekiq/blob/v6.4.2/lib/sidekiq/scheduled.rb#L173-L175)
require 'sidekiq/version'
require 'sidekiq/cron/version'

if Gem::Version.new(Sidekiq::VERSION) != Gem::Version.new('6.4.2')
  raise 'New version of sidekiq detected, please remove or update this patch'
end

if Gem::Version.new(Sidekiq::Cron::VERSION) != Gem::Version.new('1.8.0')
  raise 'New version of sidekiq-cron detected, please remove or update this patch'
end

module Gitlab
  module Patch
    module SidekiqCronPoller
      def poll_interval_average
        # Note: This diverges from the Sidekiq implementation in 6.4.2 to address a bug where the poll interval wouldn't
        # scale properly when the process count changes, and to take into account the `cron_poll_interval` setting. See
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/99030#note_1117078517 for more details
        Gitlab.config.cron_jobs.poll_interval || Sidekiq.options[:poll_interval_average] || scaled_poll_interval
      end
    end
  end
end
