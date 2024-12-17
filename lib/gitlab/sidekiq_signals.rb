# frozen_string_literal: true

module Gitlab
  # As a process group leader, we can ensure that children of sidekiq are killed
  # at the same time as sidekiq itself, to stop long-lived children from being
  # reparented to init and "escaping". To do this, we override the default
  # handlers used by sidekiq for INT and TERM signals
  module SidekiqSignals
    REPLACE_SIGNALS = %w[INT TERM].freeze

    SIDEKIQ_CHANGED_MESSAGE =
      "Intercepting signal handlers: #{REPLACE_SIGNALS.join(', ')} failed. " \
      "Sidekiq should have registered them, but appears not to have done so."

    def self.install!(sidekiq_handlers)
      # This only works if we're process group leader
      return unless Process.getpgrp == Process.pid

      raise SIDEKIQ_CHANGED_MESSAGE unless
        REPLACE_SIGNALS == sidekiq_handlers.keys & REPLACE_SIGNALS

      REPLACE_SIGNALS.each do |signal|
        old_handler = sidekiq_handlers[signal]
        sidekiq_handlers[signal] = ->(cli) do
          blindly_signal_pgroup!(signal)
          old_handler.call(cli)
        end
      end
    end

    # The process group leader can forward INT and TERM signals to the whole
    # group. However, the forwarded signal is *also* received by the leader,
    # which could lead to an infinite loop. We can avoid this by temporarily
    # ignoring the forwarded signal. This may cause us to miss some repeated
    # signals from outside the process group, but that isn't fatal.
    def self.blindly_signal_pgroup!(signal)
      old_trap = trap(signal, 'IGNORE')
      begin
        Process.kill(signal, 0)
      ensure
        trap(signal, old_trap)
      end
    end
  end
end
