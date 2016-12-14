module Gitlab
  module Ci
    module Status
      module Build
        class Factory < Status::Factory
          def self.extended_statuses
            [Status::Build::Stop, Status::Build::Play,
             Status::Build::Cancelable, Status::Build::Retryable]
          end

          def self.common_helpers
            Status::Build::Common
          end
        end
      end
    end
  end
end
