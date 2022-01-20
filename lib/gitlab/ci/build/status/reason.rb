# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Status
        class Reason
          attr_reader :build, :failure_reason, :exit_code

          def initialize(build, failure_reason, exit_code = nil)
            @build = build
            @failure_reason = failure_reason
            @exit_code = exit_code
          end

          def failure_reason_enum
            ::CommitStatus.failure_reasons[failure_reason]
          end

          def force_allow_failure?
            return false if exit_code.nil?

            !build.allow_failure? && build.allowed_to_fail_with_code?(exit_code)
          end

          def self.fabricate(build, reason)
            if reason.is_a?(self)
              new(build, reason.failure_reason, reason.exit_code)
            else
              new(build, reason)
            end
          end
        end
      end
    end
  end
end
