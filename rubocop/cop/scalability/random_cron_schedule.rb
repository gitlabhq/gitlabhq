# frozen_string_literal: true

module RuboCop
  module Cop
    module Scalability
      # Detects the use of `rand` inside cron job settings (e.g. Settings.cron_jobs),
      # which may produce randomized cron expressions. Randomization can lead to missed job
      # executions and unpredictable scheduling behavior.
      #
      # Instead of using `rand`, developers should use `Gitlab::Scheduling::ScheduleWithinWorker`
      # to safely apply jitter at runtime while keeping the cron expression deterministic.
      #
      # @example
      #   # bad
      #   Settings.cron_jobs['my_worker'] = {
      #     cron: \"#{rand(0..59)} * * * *\"
      #   }
      #
      #   # good
      #   Settings.cron_jobs['my_worker'] = {
      #     cron: '0 * * * *'
      #   }
      #
      #   # See:
      #   # https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/gitlab/scheduling/schedule_within_worker.rb
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
