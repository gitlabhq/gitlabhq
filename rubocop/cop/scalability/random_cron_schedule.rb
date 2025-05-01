# frozen_string_literal: true

module RuboCop
  module Cop
    module Scalability
      # Cop that detects use of randomized cron expressions for sidekiq-cron.
      #
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/536393
      class RandomCronSchedule < RuboCop::Cop::Base
        MSG = "Avoid randomized cron expressions. This can lead to missed executions. " \
          "Use Gitlab::Scheduling::ScheduleWithinWorker if you want to add random jitter. " \
          "See https://gitlab.com/gitlab-org/gitlab/-/issues/536393"

        RESTRICT_ON_SEND = %i[rand].freeze

        # @!method cron_job_setting?(node)
        def_node_matcher :cron_job_setting?, <<~PATTERN
          `(send (const nil? :Settings) :cron_jobs)
        PATTERN

        def on_send(node)
          return if node.each_ancestor.none? { |ancestor| cron_job_setting?(ancestor) }

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
