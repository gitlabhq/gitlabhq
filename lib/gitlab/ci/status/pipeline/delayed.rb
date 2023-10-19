# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Pipeline
        class Delayed < Status::Extended
          def text
            s_('CiStatusText|Delayed')
          end

          def label
            s_('CiStatusLabel|waiting for delayed job')
          end

          def self.matches?(pipeline, user)
            pipeline.scheduled?
          end
        end
      end
    end
  end
end
