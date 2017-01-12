module Gitlab
  module Ci
    module Status
      class Factory
        def initialize(subject, user)
          @subject = subject
          @user = user
        end

        def fabricate!
          if extended_statuses.none?
            core_status
          else
            extended_statuses.inject(core_status) do |status, extended|
              extended.new(status)
            end
          end
        end

        def self.extended_statuses
          []
        end

        def self.common_helpers
          Module.new
        end

        private

        def simple_status
          @simple_status ||= @subject.status || :created
        end

        def core_status
          Gitlab::Ci::Status
            .const_get(simple_status.capitalize)
            .new(@subject, @user)
            .extend(self.class.common_helpers)
        end

        def extended_statuses
          return @extended_statuses if defined?(@extended_statuses)

          groups = self.class.extended_statuses.map do |group|
            Array(group).find { |status| status.matches?(@subject, @user) }
          end

          @extended_statuses = groups.flatten.compact
        end
      end
    end
  end
end
