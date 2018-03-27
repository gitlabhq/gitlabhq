# frozen_string_literal: true

module Gitlab
  module GithubImport
    # NotifyUponDeath can be included into a GitHub worker class if it should
    # notify any JobWaiter instances upon being moved to the Sidekiq dead queue.
    #
    # Note that this will only notify the waiter upon graceful termination, a
    # SIGKILL will still result in the waiter _not_ being notified.
    #
    # Workers including this module must have jobs passed where the last
    # argument is the key to notify, as a String.
    module NotifyUponDeath
      extend ActiveSupport::Concern

      included do
        # If a job is being exhausted we still want to notify the
        # AdvanceStageWorker. This prevents the entire import from getting stuck
        # just because 1 job threw too many errors.
        sidekiq_retries_exhausted do |job|
          args = job['args']
          jid = job['jid']

          if args.length == 3 && (key = args.last) && key.is_a?(String)
            JobWaiter.notify(key, jid)
          end
        end
      end
    end
  end
end
