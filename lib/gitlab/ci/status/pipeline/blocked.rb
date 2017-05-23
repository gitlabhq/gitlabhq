module Gitlab
  module Ci
    module Status
      module Pipeline
        class Blocked < Status::Extended
          def text
            s_('CiStatus|blocked')
          end

          def label
            s_('CiStatus|waiting for manual action')
          end

          def self.matches?(pipeline, user)
            pipeline.blocked?
          end
        end
      end
    end
  end
end
