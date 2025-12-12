# frozen_string_literal: true

module API
  module Helpers
    module RunnerControllerHelpers
      include Gitlab::Utils::StrongMemoize

      def runner_controller
        runner_controller_token&.runner_controller
      end

      def runner_controller_token
        runner_controller_token_from_authorization_token
      end
      strong_memoize_attr :runner_controller_token

      def check_runner_controller_token!
        unauthorized! unless runner_controller_token
      end
    end
  end
end
