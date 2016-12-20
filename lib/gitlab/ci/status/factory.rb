module Gitlab
  module Ci
    module Status
      class Factory
        def initialize(subject, user)
          @subject = subject
          @user = user
        end

        def fabricate!
          if extended_status
            extended_status.new(core_status)
          else
            core_status
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

        def extended_status
          @extended ||= self.class.extended_statuses.find do |status|
            status.matches?(@subject, @user)
          end
        end
      end
    end
  end
end
