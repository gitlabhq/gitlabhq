# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Factory
        def initialize(subject, user)
          @subject = subject
          @user = user
          @status = subject.status || ::Ci::HasStatus::DEFAULT_STATUS
        end

        def fabricate!
          if extended_statuses.none?
            core_status
          else
            compound_extended_status
          end
        end

        def core_status
          Gitlab::Ci::Status
            .const_get(@status.to_s.camelize, false)
            .new(@subject, @user)
            .extend(self.class.common_helpers)
        end

        def compound_extended_status
          extended_statuses.inject(core_status) do |status, extended|
            extended.new(status)
          end
        end

        def extended_statuses
          return @extended_statuses if defined?(@extended_statuses)

          @extended_statuses = self.class.extended_statuses.flat_map do |group|
            Array(group).find { |status| status.matches?(@subject, @user) }
          end.compact
        end

        def self.extended_statuses
          []
        end

        def self.common_helpers
          Module.new
        end
      end
    end
  end
end
