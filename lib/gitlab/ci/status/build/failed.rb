module Gitlab
  module Ci
    module Status
      module Build
        class Failed < Status::Extended
          REASONS = {
            unknown_failure: 'unknown failure',
            script_failure: 'script failure',
            api_failure: 'API failure',
            stuck_or_timeout_failure: 'stuck or timeout failure',
            runner_system_failure: 'runner system failure',
            missing_dependency_failure: 'missing dependency failure',
            runner_unsupported: 'unsupported runner'
          }.freeze

          private_constant :REASONS
          prepend ::EE::Gitlab::Ci::Status::Build::Failed

          def status_tooltip
            base_message
          end

          def badge_tooltip
            base_message
          end

          def self.matches?(build, user)
            build.failed?
          end

          def self.reasons
            REASONS
          end

          private

          def base_message
            "#{s_('CiStatusLabel|failed')} #{description}"
          end

          def description
            "- (#{failure_reason_message})"
          end

          def failure_reason_message
            self.class.reasons.fetch(subject.failure_reason.to_sym)
          end
        end
      end
    end
  end
end
