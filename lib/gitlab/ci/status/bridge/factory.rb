# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        class Factory < Status::Factory
          def self.extended_statuses
            [[Status::Bridge::Retryable],
             [Status::Bridge::Failed],
             [Status::Bridge::Manual],
             [Status::Bridge::WaitingForApproval],
             [Status::Bridge::WaitingForResource],
             [Status::Bridge::Play],
             [Status::Bridge::Action],
             [Status::Bridge::Retried]]
          end

          def self.common_helpers
            Status::Bridge::Common
          end
        end
      end
    end
  end
end
