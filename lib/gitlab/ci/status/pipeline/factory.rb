module Gitlab
  module Ci
    module Status
      module Pipeline
        class Factory
          EXTENDED_STATUSES = [Pipeline::SuccessWithWarnings]

          def initialize(pipeline)
            @pipeline = pipeline
            @status = pipeline.status || :created
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
              .new(@pipeline)
              .extend(Status::Pipeline::Common)
          end

          def extended_status
            @extended ||= EXTENDED_STATUSES.find do |status|
              status.matches?(@pipeline)
            end
          end
        end
      end
    end
  end
end
