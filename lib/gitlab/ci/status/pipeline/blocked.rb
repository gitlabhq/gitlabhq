module Gitlab
  module Ci
    module Status
      module Pipeline
        class Blocked < Status::Extended
          def text
            'blocked'
          end

          def label
            'waiting for manual action'
          end

          def self.matches?(pipeline, user)
            pipeline.blocked?
          end
        end
      end
    end
  end
end
