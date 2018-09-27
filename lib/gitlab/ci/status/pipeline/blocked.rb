module Gitlab
  module Ci
    module Status
      module Pipeline
        class Blocked < Status::Extended
          def text
            s_('CiStatusText|blocked')
          end

          def label
            s_('CiStatusLabel|waiting for manual action or delayed job')
          end

          def self.matches?(pipeline, user)
            pipeline.blocked?
          end
        end
      end
    end
  end
end
