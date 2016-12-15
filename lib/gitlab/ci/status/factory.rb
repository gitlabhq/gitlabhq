module Gitlab
  module Ci
    module Status
      class Factory
        attr_reader :subject

        def initialize(subject)
          @subject = subject
        end

        def fabricate!
          if extended_status
            extended_status.new(core_status)
          else
            core_status
          end
        end

        private

        def subject_status
          @subject_status ||= subject.status
        end

        def core_status
          Gitlab::Ci::Status
            .const_get(subject_status.capitalize)
            .new(subject)
        end

        def extended_status
          @extended ||= extended_statuses.find do |status|
            status.matches?(subject)
          end
        end

        def extended_statuses
          []
        end
      end
    end
  end
end
