# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Pipeline
        class Blocked < Status::Extended
          def text
            s_('CiStatusText|Blocked')
          end

          def label
            s_('CiStatusLabel|waiting for manual action')
          end

          def self.matches?(pipeline, user)
            pipeline.blocked?
          end
        end
      end
    end
  end
end
