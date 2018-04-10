module Gitlab
  module Ci
    module Status
      module Build
        class Factory < Status::Factory
          def self.extended_statuses
            [[Status::Build::Erased,
              Status::Build::Manual,
              Status::Build::Canceled,
              Status::Build::Created,
              Status::Build::Pending,
              Status::Build::Skipped],
             [Status::Build::Cancelable,
              Status::Build::Retryable],
             [Status::Build::Failed],
             [Status::Build::FailedAllowed,
              Status::Build::Play,
              Status::Build::Stop],
             [Status::Build::Action],
             [Status::Build::Retried],
             [Status::Build::Empty]]
          end

          def self.common_helpers
            Status::Build::Common
          end
        end
      end
    end
  end
end
