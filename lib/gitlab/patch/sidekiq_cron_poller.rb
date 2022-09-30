# frozen_string_literal: true

# Patch to address https://github.com/ondrejbartas/sidekiq-cron/issues/361
# This restores the poll interval to v1.2.0 behavior
# https://github.com/ondrejbartas/sidekiq-cron/blob/v1.2.0/lib/sidekiq/cron/poller.rb#L36-L38
# This patch only applies to v1.4.0
require 'sidekiq/cron/version'

if Gem::Version.new(Sidekiq::Cron::VERSION) != Gem::Version.new('1.4.0')
  raise 'New version of sidekiq-cron detected, please remove or update this patch'
end

module Gitlab
  module Patch
    module SidekiqCronPoller
      def enqueue
        super if poll_interval_average > 0
      end

      def poll_interval_average
        Sidekiq.options[:cron_poll_interval]
      end
    end
  end
end
