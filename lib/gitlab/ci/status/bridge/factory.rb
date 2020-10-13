# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        class Factory < Status::Factory
          def self.extended_statuses
            [[Status::Bridge::Failed],
             [Status::Bridge::Manual],
             [Status::Bridge::Play],
             [Status::Bridge::Action]]
          end

          def self.common_helpers
            Status::Bridge::Common
          end
        end
      end
    end
  end
end
