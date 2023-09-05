# frozen_string_literal: true

# NotifyUponDeath can be included into a worker class if it should
# notify any JobWaiter instances upon being moved to the Sidekiq dead queue.
#
# Note that this will only notify the waiter upon graceful termination, a
# SIGKILL will still result in the waiter _not_ being notified.
#
# Workers including this module must have jobs passed where the last
# argument is the key to notify, as a String.
module Gitlab
  module Import
    module NotifyUponDeath
      extend ActiveSupport::Concern

      included do
        # If a job is being exhausted we still want to notify the
        # Gitlab::Import::AdvanceStageWorker. This prevents the entire import from getting stuck
        # just because 1 job threw too many errors.
        sidekiq_retries_exhausted do |job|
          args = job['args']
          jid = job['jid']
          key = args.last

          next unless args.length == 3 && key.is_a?(String)

          JobWaiter.notify(key, jid, ttl: Gitlab::Import::JOB_WAITER_TTL)
        end
      end
    end
  end
end
