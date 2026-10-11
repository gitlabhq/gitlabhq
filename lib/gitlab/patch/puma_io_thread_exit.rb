# frozen_string_literal: true

module Gitlab
  module Patch
    module PumaIoThreadExit
      private

      # rubocop:disable Gitlab/ModuleWithInstanceVariables -- the fix restores Puma::ThreadPool's own thread count
      def trigger_before_thread_exit_hooks
        @spawned = @processors.size if @spawned > @processors.size

        super
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
