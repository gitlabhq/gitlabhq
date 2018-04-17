module Gitlab
  module Ci
    module Status
      module Build
        class Failed < Status::Extended
          REASONS = {
            'unknown_failure' => 'unknown failure',
            'script_failure' => 'script failure',
            'api_failure' => 'API failure',
            'stuck_or_timeout_failure' => 'stuck or timeout failure',
            'runner_system_failure' => 'runner system failure',
            'missing_dependency_failure' => 'missing dependency failure'
          }.freeze

          def status_tooltip
            base_message
          end

          def badge_tooltip
            base_message
          end

          def self.matches?(build, user)
            build.failed?
          end

          private

          def base_message
            "#{s_('CiStatusLabel|failed')} #{description}"
          end

          def description
            "<br> (#{REASONS[subject.failure_reason]})"
          end
        end
      end
    end
  end
end
