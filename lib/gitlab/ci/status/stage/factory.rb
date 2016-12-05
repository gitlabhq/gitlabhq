module Gitlab
  module Ci
    module Status
      module Stage
        class Factory
          EXTENDED_STATUSES = []

          def initialize(stage)
            @stage = stage
            @status = stage.status || :created
          end

          def fabricate!
            if extended_status
              extended_status.new(core_status)
            else
              core_status
            end
          end

          private

          def core_status
            Gitlab::Ci::Status
              .const_get(@status.capitalize)
              .new(@stage)
              .extend(Status::Pipeline::Common)
          end

          def extended_status
            @extended ||= EXTENDED_STATUSES.find do |status|
              status.matches?(@stage)
            end
          end
        end
      end
    end
  end
end
