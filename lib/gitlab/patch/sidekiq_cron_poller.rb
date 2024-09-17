# frozen_string_literal: true

# Patch to address https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1932
# It restores the behavior of `poll_internal_average` to the one from Sidekiq 6.5.7
# when the cron poll interval is not configured.
# (see https://github.com/mperham/sidekiq/blob/v6.5.7/lib/sidekiq/scheduled.rb#L176-L178)
require 'sidekiq/version'
require 'sidekiq/cron/version'

if Gem::Version.new(Sidekiq::VERSION) != Gem::Version.new('7.2.4')
  raise 'New version of sidekiq detected, please remove or update this patch'
end

if Gem::Version.new(Sidekiq::Cron::VERSION) != Gem::Version.new('1.12.0')
  raise 'New version of sidekiq-cron detected, please remove or update this patch'
end

module Gitlab
  module Patch
    module SidekiqCronPoller
      def poll_interval_average(count)
        Gitlab.config.cron_jobs.poll_interval || @config[:poll_interval_average] || scaled_poll_interval(count) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
