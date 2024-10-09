# frozen_string_literal: true

module Gitlab
  module SidekiqProcess
    class << self
      def pid
        # The sidekiq thread-local capsule is set in the Processor.
        # https://github.com/sidekiq/sidekiq/blob/v7.2.4/lib/sidekiq/processor.rb#L70
        Thread.current[:sidekiq_capsule]&.identity
      end

      def tid
        Thread.current[:sidekiq_capsule]&.tid
      end
    end
  end
end
