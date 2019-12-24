# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Build
        class Factory < Status::Factory
          def self.extended_statuses
            [[Status::Build::Erased,
              Status::Build::Scheduled,
              Status::Build::Manual,
              Status::Build::Canceled,
              Status::Build::Created,
              Status::Build::WaitingForResource,
              Status::Build::Preparing,
              Status::Build::Pending,
              Status::Build::Skipped],
             [Status::Build::Cancelable,
              Status::Build::Retryable],
             [Status::Build::FailedUnmetPrerequisites,
              Status::Build::Failed],
             [Status::Build::FailedAllowed,
              Status::Build::Unschedule,
              Status::Build::Play,
              Status::Build::Stop],
             [Status::Build::Action],
             [Status::Build::Retried]]
          end

          def self.common_helpers
            Status::Build::Common
          end
        end
      end
    end
  end
end
