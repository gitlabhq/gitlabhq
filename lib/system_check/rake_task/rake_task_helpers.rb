# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Provides the run! method intended to be called from system check rake tasks
    module RakeTaskHelpers
      include ::SystemCheck::Helpers

      def run!
        warn_user_is_not_gitlab

        if self.respond_to?(:manual_run_checks!)
          manual_run_checks!
        else
          run_checks!
        end
      end

      def run_checks!
        SystemCheck.run(name, checks)
      end

      def name
        raise NotImplementedError
      end

      def checks
        raise NotImplementedError
      end
    end
  end
end
