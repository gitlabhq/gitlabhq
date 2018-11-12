# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module External
        class Factory < Status::Factory
          def self.common_helpers
            Status::External::Common
          end
        end
      end
    end
  end
end
