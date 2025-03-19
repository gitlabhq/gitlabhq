# frozen_string_literal: true

module Gitlab
  module SidekiqProcess
    class << self
      def pid
        # The sidekiq thread-local capsule is set in the Processor.
        # https://github.com/sidekiq/sidekiq/blob/v7.3.9/lib/sidekiq/processor.rb#L74
        Thread.current[:sidekiq_capsule]&.identity
      end

      def tid
        Thread.current[:sidekiq_capsule]&.tid
      end
    end
  end
end
