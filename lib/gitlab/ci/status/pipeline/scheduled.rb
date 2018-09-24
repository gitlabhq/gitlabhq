module Gitlab
  module Ci
    module Status
      module Pipeline
        class Scheduled < Status::Extended
          def text
            s_('CiStatusText|scheduled')
          end

          def label
            s_('CiStatusLabel|waiting for scheduled job')
          end

          def self.matches?(pipeline, user)
            pipeline.scheduled?
          end
        end
      end
    end
  end
end
